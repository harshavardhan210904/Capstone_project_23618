{{ config(
    materialized='table'
) }}

with source_data as (

    select
        raw_data,
        _source_file,
        _loaded_at,
        _batch_id
    from {{ ref('br_store') }}

),

flattened_data as (

    select
        f.value as store,
        _source_file,
        _loaded_at,
        _batch_id
    from source_data,
    lateral flatten(input => raw_data:stores_data) f

),

cleaned_data as (

    select

        trim(store:store_id::string) as store_id,

        initcap(trim(store:store_name::string)) as store_name,

        initcap(trim(store:store_type::string)) as store_type,

        initcap(trim(store:region::string)) as region,

        trim(store:manager_id::string) as manager_id,

        coalesce(
            store:employee_count::number,
            0
        ) as employee_count,

        coalesce(
            store:size_sq_ft::number,
            0
        ) as size_sq_ft,

        coalesce(
            store:current_sales::number(12,2),
            0
        ) as current_sales,

        coalesce(
            store:sales_target::number(12,2),
            0
        ) as sales_target,

        coalesce(
            store:monthly_rent::number(12,2),
            0
        ) as monthly_rent,

        coalesce(
            store:is_active::boolean,
            false
        ) as is_active,

        coalesce(
            try_to_date(store:opening_date::string,'YYYY-MM-DD'),
            try_to_date(store:opening_date::string,'MM/DD/YYYY'),
            try_to_date(store:opening_date::string,'DD-MM-YYYY')
        ) as opening_date,

        coalesce(
            try_to_date(store:last_modified_date::string,'YYYY-MM-DD'),
            try_to_date(store:last_modified_date::string,'MM/DD/YYYY'),
            try_to_date(store:last_modified_date::string,'DD-MM-YYYY')
        ) as last_modified_date,

        case
            when regexp_like(
                lower(trim(store:email::string)),
                '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$'
            )
            then lower(trim(store:email::string))
            else 'INVALID'
        end as email,

        regexp_replace(
            regexp_replace(
                upper(trim(store:phone_number::string)),
                '^\\+1\\s*',
                ''
            ),
            '[(). -]',
            ''
        ) as phone_number,

        initcap(trim(store:address.street::string)) as street,

        initcap(trim(store:address.city::string)) as city,

        upper(trim(store:address.state::string)) as state,

        upper(trim(store:address.country::string)) as country,

        trim(store:address.zip_code::string) as zip_code,

        trim(store:operating_hours.weekdays::string) as weekdays,

        trim(store:operating_hours.weekends::string) as weekends,

        trim(store:operating_hours.holidays::string) as holidays,

        store:services as services,

        _source_file,

        _loaded_at,

        _batch_id

    from flattened_data

),
enriched_data as (

    select

        store_id,

        store_name,

        store_type,

        region,

        manager_id,

        employee_count,

        size_sq_ft,

        case
            when size_sq_ft < 5000 then 'Small'
            when size_sq_ft between 5000 and 10000 then 'Medium'
            when size_sq_ft > 10000 then 'Large'
            else 'Unknown'
        end as store_size_category,

        current_sales,

        sales_target,

        monthly_rent,

        case
            when sales_target > 0
            then round((current_sales / sales_target) * 100, 2)
            else null
        end as sales_target_achievement_percentage,

        case
            when employee_count > 0
            then round(current_sales / employee_count, 2)
            else null
        end as employee_efficiency,

        case
            when size_sq_ft > 0
            then round(current_sales / size_sq_ft, 2)
            else null
        end as revenue_per_sq_ft,

        case
            when sales_target > 0
                 and ((current_sales / sales_target) * 100) < 90
            then true
            else false
        end as performance_issue,

        is_active,

        opening_date,

        datediff(
            year,
            opening_date,
            current_date()
        ) as store_age_years,

        last_modified_date,

        email,

        case
            when email <> 'INVALID'
            then true
            else false
        end as is_valid_email,

        phone_number,

        case
            when regexp_like(phone_number,'^[0-9]{10,15}$')
            then true
            else false
        end as is_valid_phone,

        street,

        city,

        state,

        country,

        zip_code,

        case
            when regexp_like(zip_code,'^[0-9]{5}(-[0-9]{4})?$')
            then true
            else false
        end as is_valid_zip,

        concat_ws(
            ', ',
            street,
            city,
            state,
            country,
            zip_code
        ) as full_address,

        weekdays,

        weekends,

        holidays,

        services,

        _source_file,

        _loaded_at,

        _batch_id

    from cleaned_data

),

latest_store as (

    select *

    from enriched_data

    qualify row_number() over (

        partition by store_id

        order by

            last_modified_date desc,

            _loaded_at desc,

            _source_file desc

    ) = 1

)

select *

from latest_store
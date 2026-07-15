{{ config(
    materialized='table'
) }}

with source_data as (

    select
        raw_data,
        _source_file,
        _loaded_at,
        _batch_id
    from {{ ref('br_employee') }}

),

flattened_data as (

    select
        f.value as employee,
        _source_file,
        _loaded_at,
        _batch_id
    from source_data,
    lateral flatten(input => raw_data:employees_data) f

),

cleaned_data as (

    select

        trim(employee:employee_id::string) as employee_id,

        initcap(trim(employee:first_name::string)) as first_name,

        initcap(trim(employee:last_name::string)) as last_name,

        case
            when regexp_like(
                lower(trim(employee:email::string)),
                '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$'
            )
            then lower(trim(employee:email::string))
            else 'INVALID'
        end as email,

        regexp_replace(
            regexp_replace(
                trim(employee:phone::string),
                '^\\+1\\s*',
                ''
            ),
            '[^0-9]',
            ''
        ) as phone,

        coalesce(
            try_to_date(employee:date_of_birth::string,'YYYY-MM-DD'),
            try_to_date(employee:date_of_birth::string,'MM/DD/YYYY'),
            try_to_date(employee:date_of_birth::string,'DD-MM-YYYY')
        ) as date_of_birth,

        coalesce(
            try_to_date(employee:hire_date::string,'YYYY-MM-DD'),
            try_to_date(employee:hire_date::string,'MM/DD/YYYY'),
            try_to_date(employee:hire_date::string,'DD-MM-YYYY')
        ) as hire_date,

        coalesce(
            try_to_date(employee:last_modified_date::string,'YYYY-MM-DD'),
            try_to_date(employee:last_modified_date::string,'MM/DD/YYYY'),
            try_to_date(employee:last_modified_date::string,'DD-MM-YYYY')
        ) as last_modified_date,

        case

            when upper(trim(employee:role::string))='SALES ASSOCIATE'
                then 'Associate'

            when upper(trim(employee:role::string))='STORE MANAGER'
                then 'Manager'

            when upper(trim(employee:role::string))='SENIOR MANAGER'
                then 'Senior Manager'

            else initcap(trim(employee:role::string))

        end as role,

        initcap(trim(employee:department::string)) as department,

        trim(employee:manager_id::string) as manager_id,

        trim(employee:work_location::string) as work_location,

        initcap(trim(employee:employment_status::string)) as employment_status,

        initcap(trim(employee:education::string)) as education,

        coalesce(
            employee:salary::number(12,2),
            0
        ) as salary,

        coalesce(
            employee:current_sales::number(12,2),
            0
        ) as current_sales,

        coalesce(
            employee:sales_target::number(12,2),
            0
        ) as sales_target,

        coalesce(
            employee:performance_rating::number(3,1),
            0
        ) as performance_rating,

        initcap(trim(employee:address.street::string)) as street,

        initcap(trim(employee:address.city::string)) as city,

        upper(trim(employee:address.state::string)) as state,

        trim(employee:address.zip_code::string) as zip_code,

        employee:certifications as certifications,

        _source_file,

        _loaded_at,

        _batch_id

    from flattened_data

),
enriched_data as (

    select

        employee_id,

        first_name,

        last_name,

        concat(first_name,' ',last_name) as full_name,

        email,

        case
            when email <> 'INVALID'
            then true
            else false
        end as is_valid_email,

        phone,

        case
            when regexp_like(phone,'^[0-9]{10,15}$')
            then true
            else false
        end as is_valid_phone,

        date_of_birth,

        datediff(
            year,
            date_of_birth,
            current_date()
        ) as employee_age,

        hire_date,

        datediff(
            year,
            hire_date,
            current_date()
        ) as tenure_years,

        last_modified_date,

        role,

        department,

        manager_id,

        work_location,

        employment_status,

        education,

        salary,

        current_sales,

        sales_target,

        case
            when sales_target > 0
            then round(
                (current_sales / sales_target) * 100,
                2
            )
            else null
        end as target_achievement_percentage,

        performance_rating,

        cast(null as number) as orders_processed,

        cast(null as number(12,2)) as total_sales_amount,

        street,

        city,

        state,

        zip_code,

        case
            when regexp_like(
                zip_code,
                '^[0-9]{5}(-[0-9]{4})?$'
            )
            then true
            else false
        end as is_valid_zip,

        concat_ws(
            ', ',
            street,
            city,
            state,
            zip_code
        ) as full_address,

        certifications,

        _source_file,

        _loaded_at,

        _batch_id

    from cleaned_data

),

latest_employee as (

    select *

    from enriched_data

    qualify row_number() over (

        partition by employee_id

        order by

            last_modified_date desc,

            _loaded_at desc,

            _source_file desc

    ) = 1

)

select *

from latest_employee
-- we can still change this materialised in the project.yml file also
{{ config(
    materialized='table'
) }}

with source_data as (

    select
        raw_data,
        _source_file,
        _loaded_at,
        _batch_id
    from {{ ref('br_customer') }}

),

flattened_data as (

    select

        f.value as customer,

        _source_file,
        _loaded_at,
        _batch_id

    from source_data,

    lateral flatten(input => raw_data:customers_data) f

),

cleaned_data as (

    select

        trim(customer:customer_id::string) as customer_id,

        initcap(trim(customer:first_name::string)) as first_name,

        initcap(trim(customer:last_name::string)) as last_name,

        case
            when regexp_like(
                lower(trim(customer:email::string)),
                '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$'
            )
            then lower(trim(customer:email::string))
            else 'INVALID'
        end as email,

        regexp_replace(
            regexp_replace(
                upper(trim(customer:phone::string)),
                '^\\+1\\s*',
                ''
            ),
            '[(). -]',
            ''
        ) as phone,

        coalesce(

            try_to_date(customer:birth_date::string,'YYYY-MM-DD'),

            try_to_date(customer:birth_date::string,'MM/DD/YYYY'),

            try_to_date(customer:birth_date::string,'DD-MM-YYYY')

        ) as birth_date,

        coalesce(

            upper(trim(customer:income_bracket::string)),

            'UNKNOWN'

        ) as income_bracket,

        initcap(trim(customer:occupation::string)) as occupation,

        coalesce(

            try_to_date(customer:registration_date::string,'YYYY-MM-DD'),

            try_to_date(customer:registration_date::string,'MM/DD/YYYY'),

            try_to_date(customer:registration_date::string,'DD-MM-YYYY')

        ) as registration_date,

        coalesce(

            try_to_date(customer:last_modified_date::string,'YYYY-MM-DD'),

            try_to_date(customer:last_modified_date::string,'MM/DD/YYYY'),

            try_to_date(customer:last_modified_date::string,'DD-MM-YYYY')

        ) as last_modified_date,

        coalesce(

            try_to_date(customer:last_purchase_date::string,'YYYY-MM-DD'),

            try_to_date(customer:last_purchase_date::string,'MM/DD/YYYY'),

            try_to_date(customer:last_purchase_date::string,'DD-MM-YYYY')

        ) as last_purchase_date,

        coalesce(

            upper(trim(customer:loyalty_tier::string)),

            'UNKNOWN'

        ) as loyalty_tier,

        coalesce(

            customer:marketing_opt_in::boolean,

            false

        ) as marketing_opt_in,

        coalesce(

            upper(trim(customer:preferred_communication::string)),

            'UNKNOWN'

        ) as preferred_communication,

        coalesce(

            initcap(trim(customer:preferred_payment_method::string)),

            'Unknown'

        ) as preferred_payment_method,

        coalesce(

            customer:total_purchases::number,

            0

        ) as total_purchases,

        coalesce(

            customer:total_spend::number(12,2),

            0

        ) as total_spend,

        regexp_replace(

            initcap(trim(customer:address.street::string)),

            '[,#]',

            ''

        ) as street,

        initcap(trim(customer:address.city::string)) as city,

        upper(trim(customer:address.state::string)) as state,

        upper(trim(customer:address.country::string)) as country,

        trim(customer:address.zip_code::string) as zip_code,

        _source_file,

        _loaded_at,

        _batch_id

    from flattened_data

),
enriched_data as (

    select

        customer_id,

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
            when regexp_like(phone,'^[0-9]{9,10}X?$')
            then true
            else false
        end as is_valid_phone,

        birth_date,

        datediff(
            year,
            birth_date,
            current_date()
        ) as customer_age,

        case

            when datediff(year,birth_date,current_date()) between 18 and 35
                then 'Young'

            when datediff(year,birth_date,current_date()) between 36 and 55
                then 'Middle-aged'

            when datediff(year,birth_date,current_date()) >= 56
                then 'Senior'

            else 'Unknown'

        end as customer_segment,

        income_bracket,

        occupation,

        registration_date,

        last_modified_date,

        last_purchase_date,

        loyalty_tier,

        marketing_opt_in,

        preferred_communication,

        preferred_payment_method,

        total_purchases,

        total_spend,

        street,

        city,

        state,

        country,

        zip_code,

        concat_ws(
            ', ',
            street,
            city,
            state,
            country,
            zip_code
        ) as full_address,

        _source_file,

        _loaded_at,

        _batch_id

    from cleaned_data

),

latest_customer as (

    select *

    from enriched_data

    qualify row_number() over (

        partition by customer_id

        order by

            last_modified_date desc,

            _loaded_at desc,

            _source_file desc

    ) = 1

)

select *

from latest_customer
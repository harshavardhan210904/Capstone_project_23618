
{{ config(materialized='table') }}

with current_customers as (

    select

        {{ dbt_utils.generate_surrogate_key(['customer_id']) }} as customer_key,

        customer_id,

        full_name,

        email,

        phone,

        full_address,

        customer_segment,

        income_bracket,

        loyalty_tier,

        registration_date,

        dbt_valid_from as valid_from,

        dbt_valid_to as valid_to,

        case
            when dbt_valid_to is null then true
            else false
        end as is_current

    from {{ ref('customer_snapshot') }}

)

select *
from current_customers
where is_current = true


-- {{ config(materialized='table') }}

-- select

--     {{ dbt_utils.generate_surrogate_key(['customer_id']) }} as customer_key,

--     customer_id,

--     full_name,

--     email,

--     phone,

--     full_address,

--     customer_segment,

--     income_bracket,

--     loyalty_tier,

--     registration_date,

--     dbt_valid_from as valid_from,

--     dbt_valid_to as valid_to,

--     case
--         when dbt_valid_to is null then true
--         else false
--     end as is_current

-- from {{ ref('customer_snapshot') }}
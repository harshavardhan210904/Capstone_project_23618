{{ config(materialized='table') }}

select

    {{ dbt_utils.generate_surrogate_key(['employee_id']) }} as employee_key,

    employee_id,

    full_name,

    role,

    work_location,

    tenure_years,

    email,

    phone,

    performance_rating,

    target_achievement_percentage,

    orders_processed,

    total_sales_amount

from {{ ref('sl_employee') }}
{{ config(materialized='view') }}

select
    e.employee_id,
    e.full_name,
    e.role,
    e.work_location,
    e.tenure_years,
    e.performance_rating,
    e.target_achievement_percentage,
    e.orders_processed,
    e.total_sales_amount as employee_recorded_sales,
    count(distinct f.order_id) as total_orders,
    sum(f.quantity_sold) as total_quantity_sold,
    sum(f.total_sales_amount) as sales_from_fact,
    sum(f.profit_amount) as total_profit,
    round(avg(f.total_sales_amount), 2) as average_order_value
from {{ ref('fact_sales') }} f
join {{ ref('dim_employee') }} e
    on f.employee_key = e.employee_key
group by
    e.employee_id,
    e.full_name,
    e.role,
    e.work_location,
    e.tenure_years,
    e.performance_rating,
    e.target_achievement_percentage,
    e.orders_processed,
    e.total_sales_amount
order by
    e.tenure_years desc,
    sales_from_fact desc
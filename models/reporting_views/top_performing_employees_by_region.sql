{{ config(materialized='view') }}

select
    e.employee_id,
    e.full_name,
    e.role,
    e.work_location,
    e.performance_rating,
    e.target_achievement_percentage,
    count(distinct f.order_id) as total_orders,
    sum(f.quantity_sold) as total_quantity_sold,
    sum(f.total_sales_amount) as total_sales,
    sum(f.profit_amount) as total_profit,
    dense_rank() over (
        partition by e.work_location
        order by sum(f.total_sales_amount) desc
    ) as employee_rank
from {{ ref('fact_sales') }} f
join {{ ref('dim_employee') }} e
    on f.employee_key = e.employee_key
group by
    e.employee_id,
    e.full_name,
    e.role,
    e.work_location,
    e.performance_rating,
    e.target_achievement_percentage
order by
    e.work_location,
    employee_rank
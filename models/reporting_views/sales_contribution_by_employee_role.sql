{{ config(materialized='view') }}

select
    e.role,
    count(distinct e.employee_key) as total_employees,
    count(distinct f.order_id) as total_orders,
    sum(f.quantity_sold) as total_quantity_sold,
    sum(f.total_sales_amount) as total_sales,
    sum(f.profit_amount) as total_profit,
    avg(f.total_sales_amount) as average_sales_per_order
from {{ ref('fact_sales') }} f
join {{ ref('dim_employee') }} e
    on f.employee_key = e.employee_key
group by
    e.role
order by
    total_sales desc
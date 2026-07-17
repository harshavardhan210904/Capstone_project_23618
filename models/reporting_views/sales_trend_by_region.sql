{{ config(materialized='view') }}

select
    d.year,
    d.month,
    d.month_name,
    s.region,
    sum(f.quantity_sold) as total_quantity_sold,
    sum(f.total_sales_amount) as total_sales,
    sum(f.cost_amount) as total_cost,
    sum(f.profit_amount) as total_profit
from {{ ref('fact_sales') }} f
join {{ ref('dim_date') }} d
    on f.date_key = d.date_key
join {{ ref('dim_store') }} s
    on f.store_key = s.store_key
group by
    d.year,
    d.month,
    d.month_name,
    s.region
order by
    d.year,
    d.month,
    s.region
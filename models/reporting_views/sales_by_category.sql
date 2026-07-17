{{ config(materialized='view') }}

select
    p.category,
    p.subcategory,
    sum(f.quantity_sold) as total_quantity_sold,
    sum(f.total_sales_amount) as total_sales,
    sum(f.cost_amount) as total_cost,
    sum(f.profit_amount) as total_profit
from {{ ref('fact_sales') }} f
join {{ ref('dim_product') }} p
    on f.product_key = p.product_key
group by
    p.category,
    p.subcategory
order by
    total_sales desc
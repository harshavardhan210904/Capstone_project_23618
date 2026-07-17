{{ config(materialized='view') }}

select
    p.product_id,
    p.product_name,
    p.category,
    p.subcategory,
    sum(f.quantity_sold) as total_quantity_sold,
    sum(f.total_sales_amount) as total_sales,
    sum(f.profit_amount) as total_profit,
    dense_rank() over (
        order by sum(f.total_sales_amount) desc
    ) as sales_rank
from {{ ref('fact_sales') }} f
join {{ ref('dim_product') }} p
    on f.product_key = p.product_key
group by
    p.product_id,
    p.product_name,
    p.category,
    p.subcategory
order by
    sales_rank
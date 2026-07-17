{{ config(materialized='view') }}

select
    c.customer_id,
    c.full_name,
    c.email,
    c.customer_segment,
    c.income_bracket,
    c.loyalty_tier,
    count(distinct f.order_id) as total_orders,
    sum(f.quantity_sold) as total_quantity_purchased,
    sum(f.total_sales_amount) as lifetime_value,
    sum(f.profit_amount) as total_profit,
    avg(f.total_sales_amount) as average_order_value
from {{ ref('fact_sales') }} f
join {{ ref('dim_customer') }} c
    on f.customer_key = c.customer_key
group by
    c.customer_id,
    c.full_name,
    c.email,
    c.customer_segment,
    c.income_bracket,
    c.loyalty_tier
order by
    lifetime_value desc
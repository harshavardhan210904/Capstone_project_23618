{{ config(materialized='view') }}

select
    c.customer_segment,
    c.income_bracket,
    c.loyalty_tier,
    count(distinct c.customer_key) as total_customers,
    count(distinct f.order_id) as total_orders,
    sum(f.quantity_sold) as total_quantity_sold,
    sum(f.total_sales_amount) as total_sales,
    sum(f.profit_amount) as total_profit,
    round(avg(f.total_sales_amount), 2) as average_order_value
from {{ ref('fact_sales') }} f
join {{ ref('dim_customer') }} c
    on f.customer_key = c.customer_key
group by
    c.customer_segment,
    c.income_bracket,
    c.loyalty_tier
order by
    total_sales desc
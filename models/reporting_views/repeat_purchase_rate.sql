{{ config(materialized='view') }}

select
    c.customer_id,
    c.full_name,
    c.customer_segment,
    c.loyalty_tier,
    count(distinct f.order_id) as total_orders,
    sum(f.total_sales_amount) as total_sales,
    case
        when count(distinct f.order_id) > 1 then 'Repeat Customer'
        else 'One-Time Customer'
    end as purchase_type
from {{ ref('fact_sales') }} f
join {{ ref('dim_customer') }} c
    on f.customer_key = c.customer_key
group by
    c.customer_id,
    c.full_name,
    c.customer_segment,
    c.loyalty_tier
order by
    total_orders desc,
    total_sales desc
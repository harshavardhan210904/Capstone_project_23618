{{ config(
    materialized='table'
) }}

select

    {{ dbt_utils.generate_surrogate_key(['o.order_id','o.product_id']) }} as sales_key,

    o.order_id,

    c.customer_key,

    p.product_key,

    s.store_key,

    e.employee_key,

    d.date_key,

    o.total_quantity as quantity_sold,

    o.unit_price,

    o.line_revenue as total_sales_amount,

    o.line_cost as cost_amount,

    o.discount_amount,

    o.shipping_cost,

    o.profit_amount,

    s.region,

    o.order_source as sales_channel,

    c.customer_segment as customer_segment_impact

from {{ ref('sl_order') }} o

left join {{ ref('dim_customer') }} c
    on o.customer_id = c.customer_id
    and c.is_current = true

left join {{ ref('dim_product') }} p
    on o.product_id = p.product_id

left join {{ ref('dim_store') }} s
    on o.store_id = s.store_id

left join {{ ref('dim_employee') }} e
    on o.employee_id = e.employee_id

left join {{ ref('dim_date') }} d
    on cast(o.order_date as date) = d.full_date
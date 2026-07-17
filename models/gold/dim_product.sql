{{ config(materialized='table') }}

select

    {{ dbt_utils.generate_surrogate_key(['product_id']) }} as product_key,

    product_id,

    product_name,

    category,

    subcategory,

    brand,

    color,

    size,

    unit_price,

    cost_price,

    supplier_id,

    warranty_period,

    product_line

from {{ ref('sl_product') }}
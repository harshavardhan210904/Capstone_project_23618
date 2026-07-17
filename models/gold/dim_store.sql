{{ config(materialized='table') }}

select

    {{ dbt_utils.generate_surrogate_key(['store_id']) }} as store_key,

    store_id,

    store_name,

    full_address as address,

    region,

    store_type,

    opening_date,

    store_size_category

from {{ ref('sl_store') }}
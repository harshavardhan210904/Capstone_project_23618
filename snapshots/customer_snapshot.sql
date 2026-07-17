{% snapshot customer_snapshot %}

{{
    config(
        target_schema='SNAPSHOTS',
        unique_key='customer_id',
        strategy='check',
        check_cols='all'
    )
}}

select *
from {{ ref('sl_customer') }}

{% endsnapshot %}
select
    raw_data,
    source_file as _source_file,
    current_timestamp() as _loaded_at,
    '{{ invocation_id }}' as _batch_id
from {{ source('bronze_external', 'EXT_SUPPLIER_DATA') }}

{% if is_incremental() %}

where source_file not in (

    select distinct _source_file

    from {{ this }}

)

{% endif %}
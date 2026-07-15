{{ config(
    materialized='table'
) }}

with source_data as (

    select
        raw_data,
        _source_file,
        _loaded_at,
        _batch_id
    from {{ ref('br_product') }}

),

flattened_data as (

    select

        f.value as product,

        _source_file,
        _loaded_at,
        _batch_id

    from source_data,

    lateral flatten(input => raw_data:products_data) f

),

cleaned_data as (

    select

        trim(product:product_id::string) as product_id,

        initcap(trim(product:name::string)) as product_name,

        initcap(trim(product:brand::string)) as brand,

        initcap(trim(product:category::string)) as category,

        initcap(trim(product:subcategory::string)) as subcategory,

        initcap(trim(product:product_line::string)) as product_line,

        initcap(trim(product:color::string)) as color,

        initcap(trim(product:size::string)) as size,

        trim(product:weight::string) as weight,

        trim(product:dimensions::string) as dimensions,

        coalesce(
            product:cost_price::number(10,2),
            0
        ) as cost_price,

        coalesce(
            product:unit_price::number(10,2),
            0
        ) as unit_price,

        coalesce(
            product:stock_quantity::number,
            0
        ) as stock_quantity,

        coalesce(
            product:reorder_level::number,
            0
        ) as reorder_level,

        coalesce(
            product:is_featured::boolean,
            false
        ) as is_featured,

        trim(product:supplier_id::string) as supplier_id,

        coalesce(

            try_to_date(product:launch_date::string,'YYYY-MM-DD'),

            try_to_date(product:launch_date::string,'MM/DD/YYYY'),

            try_to_date(product:launch_date::string,'DD-MM-YYYY')

        ) as launch_date,

        coalesce(

            try_to_date(product:last_modified_date::string,'YYYY-MM-DD'),

            try_to_date(product:last_modified_date::string,'MM/DD/YYYY'),

            try_to_date(product:last_modified_date::string,'DD-MM-YYYY')

        ) as last_modified_date,

        initcap(trim(product:warranty_period::string)) as warranty_period,

        trim(product:technical_specs::string) as technical_specs,

        initcap(trim(product:short_description::string)) as short_description,

        concat_ws(

            ' - ',

            initcap(trim(product:name::string)),

            initcap(trim(product:short_description::string)),

            trim(product:technical_specs::string)

        ) as product_full_description,

        concat_ws(

            ' > ',

            initcap(trim(product:category::string)),

            initcap(trim(product:subcategory::string)),

            initcap(trim(product:product_line::string))

        ) as product_hierarchy,

        case

            when product:unit_price::number > 0

            then round(

                (

                    (

                        product:unit_price::number

                        -

                        product:cost_price::number

                    )

                    /

                    product:unit_price::number

                ) * 100,

                2

            )

            else null

        end as profit_margin_percentage,

        case

            when product:stock_quantity::number

                 <

                 product:reorder_level::number

            then true

            else false

        end as is_low_stock,

        _source_file,

        _loaded_at,

        _batch_id

    from flattened_data

),
latest_product as (

    select *

    from cleaned_data

    qualify row_number() over (

        partition by product_id

        order by

            last_modified_date desc,

            _loaded_at desc,

            _source_file desc

    ) = 1

)

select

    product_id,

    product_name,

    brand,

    category,

    subcategory,

    product_line,

    color,

    size,

    weight,

    dimensions,

    cost_price,

    unit_price,

    stock_quantity,

    reorder_level,

    is_featured,

    supplier_id,

    launch_date,

    last_modified_date,

    warranty_period,

    technical_specs,

    short_description,

    product_full_description,

    product_hierarchy,

    profit_margin_percentage,

    is_low_stock,

    _source_file,

    _loaded_at,

    _batch_id

from latest_product
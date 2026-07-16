{{ config(
    materialized='table'
) }}

with source_data as (

    select
        raw_data,
        _source_file,
        _loaded_at,
        _batch_id
    from {{ ref('br_orders') }}

),

cleaned_data as (

    select

        trim(raw_data:order_id::string) as order_id,

        trim(raw_data:customer_id::string) as customer_id,

        trim(raw_data:employee_id::string) as employee_id,

        trim(raw_data:store_id::string) as store_id,

        trim(raw_data:campaign_id::string) as campaign_id,

        raw_data:order_date::timestamp_ntz as order_date,

        raw_data:shipping_date::timestamp_ntz as shipping_date,

        raw_data:estimated_delivery_date::timestamp_ntz as estimated_delivery_date,

        raw_data:delivery_date::timestamp_ntz as delivery_date,

        raw_data:created_at::timestamp_ntz as created_at,

        initcap(trim(raw_data:order_status::string)) as order_status,

        initcap(trim(raw_data:order_source::string)) as order_source,

        initcap(trim(raw_data:payment_method::string)) as payment_method,

        initcap(trim(raw_data:shipping_method::string)) as shipping_method,

        coalesce(raw_data:shipping_cost::number(12,2),0) as shipping_cost,

        coalesce(raw_data:tax_amount::number(12,2),0) as tax_amount,

        coalesce(raw_data:discount_amount::number(12,2),0) as discount_amount,

        coalesce(raw_data:total_amount::number(12,2),0) as total_amount,

        initcap(trim(raw_data:billing_address.street::string)) as billing_street,

        initcap(trim(raw_data:billing_address.city::string)) as billing_city,

        upper(trim(raw_data:billing_address.state::string)) as billing_state,

        trim(raw_data:billing_address.zip_code::string) as billing_zip_code,

        initcap(trim(raw_data:shipping_address.street::string)) as shipping_street,

        initcap(trim(raw_data:shipping_address.city::string)) as shipping_city,

        upper(trim(raw_data:shipping_address.state::string)) as shipping_state,

        trim(raw_data:shipping_address.zip_code::string) as shipping_zip_code,

        raw_data:order_items as order_items,

        _source_file,

        _loaded_at,

        _batch_id

    from source_data

),

flattened_items as (

    select

        c.order_id,

        c.customer_id,

        c.employee_id,

        c.store_id,

        c.campaign_id,

        c.order_date,

        c.shipping_date,

        c.estimated_delivery_date,

        c.delivery_date,

        c.created_at,

        c.order_status,

        c.order_source,

        c.payment_method,

        c.shipping_method,

        c.shipping_cost,

        c.tax_amount,

        c.discount_amount,

        c.total_amount,

        c.billing_street,

        c.billing_city,

        c.billing_state,

        c.billing_zip_code,

        c.shipping_street,

        c.shipping_city,

        c.shipping_state,

        c.shipping_zip_code,

        f.value:product_id::string as product_id,

        coalesce(f.value:quantity::number,0) as quantity,

        coalesce(f.value:unit_price::number(12,2),0) as unit_price,

        coalesce(f.value:cost_price::number(12,2),0) as cost_price,

        coalesce(f.value:discount_amount::number(12,2),0) as item_discount_amount,

        _source_file,

        _loaded_at,

        _batch_id

    from cleaned_data c,

    lateral flatten(input => c.order_items) f

),
aggregated_orders as (

    select

        order_id,

        any_value(customer_id) as customer_id,
        any_value(employee_id) as employee_id,
        any_value(store_id) as store_id,
        any_value(campaign_id) as campaign_id,

        any_value(order_date) as order_date,
        any_value(shipping_date) as shipping_date,
        any_value(estimated_delivery_date) as estimated_delivery_date,
        any_value(delivery_date) as delivery_date,
        any_value(created_at) as created_at,

        any_value(order_status) as order_status,
        any_value(order_source) as order_source,
        any_value(payment_method) as payment_method,
        any_value(shipping_method) as shipping_method,

        any_value(shipping_cost) as shipping_cost,
        any_value(tax_amount) as tax_amount,
        any_value(discount_amount) as discount_amount,
        any_value(total_amount) as total_amount,

        any_value(billing_street) as billing_street,
        any_value(billing_city) as billing_city,
        any_value(billing_state) as billing_state,
        any_value(billing_zip_code) as billing_zip_code,

        any_value(shipping_street) as shipping_street,
        any_value(shipping_city) as shipping_city,
        any_value(shipping_state) as shipping_state,
        any_value(shipping_zip_code) as shipping_zip_code,

        count(product_id) as total_items,

        sum(quantity) as total_quantity,

        sum((quantity * unit_price) - item_discount_amount) as line_revenue,

        sum(quantity * cost_price) as line_cost,

        any_value(_source_file) as _source_file,
        any_value(_loaded_at) as _loaded_at,
        any_value(_batch_id) as _batch_id

    from flattened_items

    group by order_id

),

enriched_orders as (

    select

        *,

        line_revenue
        - line_cost
        - shipping_cost
        - tax_amount
        as profit_amount,

        case

            when line_revenue > 0

            then round(

                (
                    (
                        line_revenue
                        - line_cost
                        - shipping_cost
                        - tax_amount
                    )
                    / line_revenue
                ) * 100

            ,2)

            else null

        end as profit_margin_percentage,

        datediff(
            day,
            order_date,
            shipping_date
        ) as processing_days,

        datediff(
            day,
            shipping_date,
            delivery_date
        ) as shipping_days,

        datediff(
            day,
            order_date,
            delivery_date
        ) as delivery_days,

        case

            when delivery_date <= estimated_delivery_date

            then 'On Time'

            when delivery_date > estimated_delivery_date

            then 'Delayed'

            else 'Pending'

        end as delivery_status,

        case

            when extract(hour from order_date) between 5 and 11

            then 'Morning'

            when extract(hour from order_date) between 12 and 16

            then 'Afternoon'

            when extract(hour from order_date) between 17 and 21

            then 'Evening'

            else 'Night'

        end as order_time_of_day,

        week(order_date) as order_week,

        month(order_date) as order_month,

        quarter(order_date) as order_quarter,

        year(order_date) as order_year,

        concat_ws(
            ', ',
            billing_street,
            billing_city,
            billing_state,
            billing_zip_code
        ) as billing_address,

        concat_ws(
            ', ',
            shipping_street,
            shipping_city,
            shipping_state,
            shipping_zip_code
        ) as shipping_address,

        regexp_like(
            billing_zip_code,
            '^[0-9]{5}(-[0-9]{4})?$'
        ) as is_valid_billing_zip,

        regexp_like(
            shipping_zip_code,
            '^[0-9]{5}(-[0-9]{4})?$'
        ) as is_valid_shipping_zip

    from aggregated_orders

),

latest_order as (

    select *

    from enriched_orders

    qualify row_number() over (

        partition by order_id

        order by

            created_at desc,

            _loaded_at desc,

            _source_file desc

    ) = 1

)

select *

from latest_order
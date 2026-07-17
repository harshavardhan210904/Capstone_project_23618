{% macro create_all_external_tables() %}

{{ create_external_table(
    table_name='ext_customer_data',
    stage_name='ADLS_STAGE',
    folder_path='Capstone_Project_Data/customer_data'
) }}

{{ create_external_table(
    table_name='ext_orders_data',
    stage_name='ADLS_STAGE',
    folder_path='Capstone_Project_Data/orders_data'
) }}

{{ create_external_table(
    table_name='ext_supplier_data',
    stage_name='ADLS_STAGE',
    folder_path='Capstone_Project_Data/supplier_data'
) }}

{{ create_external_table(
    table_name='ext_product_data',
    stage_name='ADLS_STAGE',
    folder_path='Capstone_Project_Data/product_data'
) }}

{{ create_external_table(
    table_name='ext_employee_data',
    stage_name='ADLS_STAGE',
    folder_path='Capstone_Project_Data/employee_data'
) }}

{{ create_external_table(
    table_name='ext_campaign_data',
    stage_name='ADLS_STAGE',
    folder_path='Capstone_Project_Data/campaign_data'
) }}

{{ create_external_table(
    table_name='ext_store_data',
    stage_name='ADLS_STAGE',
    folder_path='Capstone_Project_Data/store_data'
) }}

{% endmacro %}
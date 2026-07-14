{% macro create_external_table(schema_name, table_name, folder_name) %}

CREATE OR REPLACE EXTERNAL TABLE {{ target.database }}.{{ schema_name }}.{{ table_name }}
(
    raw_data VARIANT AS ($1),
    source_file STRING AS (METADATA$FILENAME)
)
WITH LOCATION = @ADLS_STAGE/Capstone_Project_Data/{{ folder_name }}
FILE_FORMAT = (FORMAT_NAME = JSON_FILE_FORMAT)
AUTO_REFRESH = FALSE;

{% endmacro %}


-- {% macro create_external_table(table_name, folder_name) %}

-- CREATE OR REPLACE EXTERNAL TABLE {{ target.database }}.BRONZE.{{ table_name }}
-- (
--     raw_data VARIANT AS ($1),
--     source_file STRING AS (METADATA$FILENAME)
-- )
-- WITH LOCATION = @ADLS_STAGE/Capstone_Project_Data/{{ folder_name }}
-- FILE_FORMAT = (FORMAT_NAME = JSON_FILE_FORMAT)
-- AUTO_REFRESH = FALSE;

-- {% endmacro %}

-- {% macro create_external_table(table_name, folder_name) %}

-- CREATE OR REPLACE EXTERNAL TABLE {{ table_name }}
-- (
--     raw_data VARIANT,
--     filename STRING AS (METADATA$FILENAME)
-- )
-- LOCATION = @ADLS_STAGE/Capstone_Project_Data/{{ folder_name }}
-- AUTO_REFRESH = FALSE
-- FILE_FORMAT = (FORMAT_NAME = JSON_FILE_FORMAT);

-- {% endmacro %}
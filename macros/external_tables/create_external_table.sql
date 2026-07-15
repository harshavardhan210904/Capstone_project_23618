-- Define a reusable dbt macro named create_external_table
{% macro create_external_table(
        table_name,        
        stage_name,        
        folder_path        
    )
%}

-- Store the SQL statement inside a variable named 'sql'
{% set sql %}

-- Create the external table. If it already exists, replace it.
CREATE OR REPLACE EXTERNAL TABLE {{ target.database }}.BRONZE_23618.{{ table_name }}

(
    -- Store the complete JSON object in a VARIANT column
    raw_data VARIANT AS (VALUE),

    -- Store the source JSON filename in a separate column
    source_file VARCHAR AS (METADATA$FILENAME),
    file_last_modified TIMESTAMP AS (METADATA$FILE_LAST_MODIFIED)
)

-- Specify the location of the JSON files inside the external stage
LOCATION = @{{ stage_name }}/{{ folder_path }}

-- Disable automatic refresh when new files are added
AUTO_REFRESH = FALSE

-- Specify that the files in the folder are JSON files
FILE_FORMAT = (
    TYPE = JSON
);

-- End of the SQL statement
{% endset %}

-- Print the generated SQL in the dbt logs (useful for debugging)
{{ log(sql, info=True) }}

-- Execute the SQL statement in Snowflake
{{ run_query(sql) }}

-- End of the macro
{% endmacro %}
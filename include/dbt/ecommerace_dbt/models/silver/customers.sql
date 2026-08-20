{{ config(
    materialized='table',
    schema='silver'
) }}

select
    nullif(customer_id, '')::varchar(50) as customer_id,
    nullif(customer_unique_id, '')::varchar(50) as customer_unique_id,
    nullif(customer_zip_code_prefix, '')::integer as customer_zip_code_prefix,
    nullif(customer_city, '')::varchar(100) as customer_city,
    nullif(customer_state, '')::varchar(10) as customer_state
from {{ source('bronze', 'customers') }}
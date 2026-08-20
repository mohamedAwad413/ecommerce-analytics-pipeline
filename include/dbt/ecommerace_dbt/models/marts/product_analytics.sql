{{ config(
    materialized='table',
    schema='gold'
) }}

select
    p.product_id,
    p.clean_category_name,
    p.product_weight_g,
    p.product_volume_cm3,
    p.weight_category
from {{ ref('products') }} p

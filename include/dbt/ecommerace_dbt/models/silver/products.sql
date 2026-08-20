{{ config(
    materialized='table',
    schema='silver'
) }}

with cleaned_products as (

    select
        nullif(product_id, '')::varchar(50) as product_id,
        nullif(product_category_name, '')::varchar(100) as product_category_name,
        nullif(product_name_lenght, '')::integer as product_name_lenght,
        nullif(product_description_lenght, '')::integer as product_description_lenght,
        nullif(product_photos_qty, '')::integer as product_photos_qty,
        nullif(product_weight_g, '')::integer as product_weight_g,
        nullif(product_length_cm, '')::integer as product_length_cm,
        nullif(product_height_cm, '')::integer as product_height_cm,
        nullif(product_width_cm, '')::integer as product_width_cm

    from {{ source('bronze', 'products') }}

)

select
    *,

   
    (
        product_length_cm
        * product_height_cm
        * product_width_cm
    ) as product_volume_cm3,

    
    case
        when product_weight_g is null then 'Unknown'
        when product_weight_g < 1000 then 'Light'
        when product_weight_g between 1000 and 5000 then 'Medium'
        else 'Heavy'
    end as weight_category,

   
    initcap(
        replace(product_category_name, '_', ' ')
    ) as clean_category_name

from cleaned_products
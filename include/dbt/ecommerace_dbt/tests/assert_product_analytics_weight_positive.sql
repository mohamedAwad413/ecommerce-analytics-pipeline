
select
    product_id,
    product_weight_g
from {{ ref('product_analytics') }}
where product_weight_g < 0
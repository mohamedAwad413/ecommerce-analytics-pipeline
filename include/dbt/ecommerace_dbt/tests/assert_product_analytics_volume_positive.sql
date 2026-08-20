select
    product_id,
    product_volume_cm3
from {{ ref('product_analytics') }}
where product_volume_cm3 < 0
select
    order_id,
    actual_delivery_days
from {{ ref('order_analytics') }}
where actual_delivery_days < 0
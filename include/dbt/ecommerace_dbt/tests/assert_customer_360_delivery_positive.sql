select
    customer_unique_id,
    avg_delivery_days
from {{ ref('customer_360') }}
where avg_delivery_days < 0
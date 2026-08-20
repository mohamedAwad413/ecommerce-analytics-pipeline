select
    order_id,
    order_purchase_timestamp,
    order_delivered_customer_date
from {{ ref('order_analytics') }}
where order_purchase_timestamp > order_delivered_customer_date
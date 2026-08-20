select
    order_id,
    is_on_time
from {{ ref('order_analytics') }}
where is_on_time is null 
and order_delivered_customer_date is not null
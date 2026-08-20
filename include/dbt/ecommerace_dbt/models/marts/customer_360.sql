{{ config(
    materialized='table',
    schema='gold'
) }}

select
    c.customer_unique_id,

    max(c.customer_city) as customer_city,
    max(c.customer_state) as customer_state,

    count(distinct o.order_id) as total_orders,

    min(o.order_purchase_timestamp) as first_order_date,
    max(o.order_purchase_timestamp) as last_order_date,

    count(
        distinct case
            when o.order_status = 'delivered'
            then o.order_id
        end
    ) as delivered_orders,

    count(
        distinct case
            when o.is_on_time = true
            then o.order_id
        end
    ) as on_time_orders,

    round(
        avg(o.actual_delivery_days)::numeric,
        2
    ) as avg_delivery_days

from {{ ref('customers') }} c

left join {{ ref('orders') }} o
    on c.customer_id = o.customer_id

group by
    c.customer_unique_id
{{ config(
    materialized='table',
    schema='gold'
) }}

select
    o.order_id,
    o.customer_id,
    c.customer_unique_id,

    o.order_status,

    o.order_purchase_timestamp,
    o.order_approved_at,
    o.order_delivered_carrier_date,
    o.order_delivered_customer_date,
    o.order_estimated_delivery_date,

    o.actual_delivery_days,
    o.is_on_time,

    o.purchase_year,
    o.purchase_month,
    o.purchase_day_of_week,

    c.customer_city,
    c.customer_state

from {{ ref('orders') }} o

left join {{ ref('customers') }} c
    on o.customer_id = c.customer_id

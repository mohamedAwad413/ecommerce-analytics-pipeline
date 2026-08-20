{{ config(
    materialized='table',
    schema='silver'
) }}

select
   
    nullif(order_id, '')::varchar(50) as order_id,
    nullif(customer_id, '')::varchar(50) as customer_id,

   
    nullif(order_status, '')::varchar(50) as order_status,

    nullif(order_purchase_timestamp, '')::timestamp as order_purchase_timestamp,
    nullif(order_approved_at, '')::timestamp as order_approved_at,
    nullif(order_delivered_carrier_date, '')::timestamp as order_delivered_carrier_date,
    nullif(order_delivered_customer_date, '')::timestamp as order_delivered_customer_date,
    nullif(order_estimated_delivery_date, '')::timestamp as order_estimated_delivery_date,

   
    extract(
        epoch from (
            nullif(order_delivered_customer_date, '')::timestamp
            - nullif(order_purchase_timestamp, '')::timestamp
        )
    ) / 86400.0 as actual_delivery_days,

  
    case
        when nullif(order_delivered_customer_date, '')::timestamp is null then null
        when nullif(order_delivered_customer_date, '')::timestamp
             <= nullif(order_estimated_delivery_date, '')::timestamp
        then true
        else false
    end as is_on_time,

   
    date_part(
        'year',
        nullif(order_purchase_timestamp, '')::timestamp
    )::integer as purchase_year,

    date_part(
        'month',
        nullif(order_purchase_timestamp, '')::timestamp
    )::integer as purchase_month,

    trim(
        to_char(
            nullif(order_purchase_timestamp, '')::timestamp,
            'Day'
        )
    ) as purchase_day_of_week

from {{ source('bronze', 'orders') }}
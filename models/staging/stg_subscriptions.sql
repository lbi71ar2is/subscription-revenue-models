{{ config(materialized='view') }}

with source as (

    select * from {{ source('billing', 'subscriptions') }}

),

renamed as (

    select
        cast(subscription_id as varchar) as subscription_id,
        cast(customer_id as varchar) as customer_id,
        cast(plan_id as varchar) as plan_id,
        lower(trim(status)) as status,
        cast(quantity as integer) as quantity,
        cast(unit_price_cents as integer) as unit_price_cents,
        upper(trim(currency)) as currency,
        cast(started_at as date) as started_at,
        cast(ended_at as date) as ended_at,
        cast(updated_at as timestamp) as updated_at

    from source
    where subscription_id is not null

)

select * from renamed

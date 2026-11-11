{{ config(materialized='table') }}

with source as (

    select * from {{ source('billing', 'plans') }}

)

select
    cast(plan_id as varchar) as plan_id,
    trim(plan_name) as plan_name,
    lower(billing_interval) as billing_interval,
    cast(included_seats as integer) as included_seats,
    cast(is_public as boolean) as is_public
from source
where plan_id is not null

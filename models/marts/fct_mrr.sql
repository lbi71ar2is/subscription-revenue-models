{{ config(materialized='table') }}

with months as (

    select cast(month_start as date) as month_start
    from generate_series(
        date '2023-01-01',
        date_trunc('month', current_date),
        interval 1 month
    ) as t(month_start)

),

subscriptions as (

    select * from {{ ref('stg_subscriptions') }}

),

plans as (

    select * from {{ ref('dim_plans') }}

),

active_months as (

    select
        s.subscription_id,
        s.customer_id,
        s.plan_id,
        m.month_start,
        last_day(m.month_start) as month_end,
        s.quantity,
        s.unit_price_cents,
        s.quantity * s.unit_price_cents as mrr_cents,
        s.currency,
        s.status

    from months m
    inner join subscriptions s
        on s.started_at <= last_day(m.month_start)
        and (s.ended_at is null or s.ended_at >= m.month_start)
    where m.month_start <= date_trunc('month', current_date)

)

select
    md5(cast(a.subscription_id || '|' || cast(a.month_start as varchar) as varchar)) as mrr_row_id,
    a.subscription_id,
    a.customer_id,
    a.plan_id,
    a.month_start,
    a.month_end,
    a.quantity,
    a.unit_price_cents,
    a.mrr_cents,
    a.currency,
    a.status,
    p.plan_name,
    p.billing_interval

from active_months a
left join plans p on p.plan_id = a.plan_id

# subscription-revenue-models

A small dbt package that turns raw subscription events into a monthly MRR
fact table and a plan dimension. It exists so that revenue numbers in
dashboards and ad hoc queries come from one tested definition instead of
three slightly different spreadsheets.

## Models and grain

| Model | Grain | Materialization |
| --- | --- | --- |
| `stg_subscriptions` | one row per subscription | view |
| `dim_plans` | one row per plan | table |
| `fct_mrr` | one row per active subscription per month | table |

`fct_mrr.mrr_cents` is `quantity * unit_price_cents`, apportioned to full
months. A subscription is active for a month when it started on or before the
last day of that month and ended on or after the first day. Cancellations are
inclusive of the month they happen in, so churn shows up in the month the
customer leaves, not the month after.

## Tests

`dbt test` enforces:

- uniqueness and non-null keys on `subscription_id` and `month_start`
- `status` restricted to `trialing`, `active`, `past_due`, `canceled`
- non-negative `quantity` and `mrr_cents`
- referential integrity from `fct_mrr.plan_id` to `dim_plans.plan_id`

A model change that breaks the grain will fail the unique combination test
before it reaches production.

## Caveats

- Everything is EUR. Multi-currency subscriptions are converted upstream in
  the source extract, not here.
- No proration: a subscription that starts mid-month contributes a full month
  of MRR. Use the daily table if you need partial periods.
- The month spine stops at the current month; future-dated subscriptions are
  excluded on purpose.
- Trials are included in `fct_mrr` with their would-be MRR, so filter on
  `status = 'active'` for booked revenue.

## Install

```bash
python -m venv .venv && . .venv/bin/activate
pip install dbt-duckdb
export DBT_PROFILES_DIR=.
dbt deps
dbt build --select +fct_mrr
```

The default profile points at `./warehouse.duckdb` and expects a
`raw.subscriptions` table plus a `raw.plans` table.

## Layout

```
models/staging/stg_subscriptions.sql   normalize raw subscription rows
models/staging/_stg_subscriptions.yml  keys, accepted values, quantity test
models/marts/dim_plans.sql             plan attributes, one row per plan
models/marts/fct_mrr.sql               monthly active subscription spine
```

## License

MIT, see [LICENSE](LICENSE).

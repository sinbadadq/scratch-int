SELECT
    COUNT(*)                        AS total_rows,
    COUNT(DISTINCT merchant_id)     AS unique_merchants,
    COUNT(DISTINCT country_code)    AS unique_countries
FROM subscriptions;


-- Top 10 countries by number of subscriptions
SELECT
    country_code,
    COUNT(*)                                            AS total_rows,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 2) AS pct_of_total
FROM subscriptions
GROUP BY country_code
ORDER BY total_rows DESC
LIMIT 10;


-- Top 10 merchants by number of subscriptions
SELECT
    merchant_id,
    COUNT(*)                                            AS total_rows,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 2) AS pct_of_total
FROM subscriptions
GROUP BY merchant_id
ORDER BY total_rows DESC
LIMIT 10;


-- Date range and granularity of created_at
SELECT
    MIN(created_at)                                     AS earliest_created_at,
    MAX(created_at)                                     AS latest_created_at,
    COUNT(DISTINCT DATE_TRUNC('year',  created_at))     AS unique_years,
    COUNT(DISTINCT DATE_TRUNC('month', created_at))     AS unique_months,
    COUNT(DISTINCT DATE_TRUNC('day',   created_at))     AS unique_days
FROM subscriptions;


-- Date range and granularity of cancelled_at
SELECT
    MIN(cancelled_at)                                   AS earliest_cancelled_at,
    MAX(cancelled_at)                                   AS latest_cancelled_at,
    COUNT(DISTINCT DATE_TRUNC('year',  cancelled_at))   AS unique_years,
    COUNT(DISTINCT DATE_TRUNC('month', cancelled_at))   AS unique_months,
    COUNT(DISTINCT DATE_TRUNC('day',   cancelled_at))   AS unique_days
FROM subscriptions;


-- Date range and granularity of trial_ends_at
SELECT
    MIN(trial_ends_at)                                  AS earliest_trial_ends_at,
    MAX(trial_ends_at)                                  AS latest_trial_ends_at,
    COUNT(DISTINCT DATE_TRUNC('year',  trial_ends_at))  AS unique_years,
    COUNT(DISTINCT DATE_TRUNC('month', trial_ends_at))  AS unique_months,
    COUNT(DISTINCT DATE_TRUNC('day',   trial_ends_at))  AS unique_days
FROM subscriptions;


-- Percent of non-null cancelled_at and trial_ends_at
SELECT
    ROUND(COUNT(cancelled_at)  * 100.0 / COUNT(*), 2)  AS pct_cancelled_at_non_null,
    ROUND(COUNT(trial_ends_at) * 100.0 / COUNT(*), 2)  AS pct_trial_ends_at_non_null
FROM subscriptions;


-- Number of records created on February 29, 2024
SELECT
    COUNT(*) AS total_rows
FROM subscriptions
WHERE DATE_TRUNC('day', created_at) = '2024-02-29';


-- Status breakdown for records with a non-null cancelled_at
SELECT
    status,
    COUNT(*)                                            AS total_rows,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 4) AS pct_of_total
FROM subscriptions
WHERE cancelled_at IS NOT NULL
GROUP BY status
ORDER BY total_rows DESC;


-- Plan breakdown for records with a non-null cancelled_at
SELECT
    plan,
    COUNT(*)                                            AS total_rows,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 2) AS pct_of_total
FROM subscriptions
WHERE cancelled_at IS NOT NULL
GROUP BY plan
ORDER BY total_rows DESC;


-- Cancellation rate by plan
SELECT
    plan,
    COUNT(*)                                                        AS total_rows,
    COUNT(cancelled_at)                                             AS total_cancelled,
    ROUND(COUNT(cancelled_at) * 100.0 / COUNT(*), 2)               AS cancellation_rate,
    ROUND(COUNT(cancelled_at) * AVG(monthly_price), 2)             AS lost_mrr
FROM subscriptions
GROUP BY plan
ORDER BY cancellation_rate DESC;


-- Quintile distribution of days to cancel for plan='plus'
WITH days_to_cancel AS (
    SELECT
        (cancelled_at::date - created_at::date)                    AS days,
        NTILE(5) OVER (ORDER BY cancelled_at::date - created_at::date) AS quintile
    FROM subscriptions
    WHERE cancelled_at IS NOT NULL
        AND plan = 'plus'
)
SELECT
    quintile,
    COUNT(*)                        AS total_rows,
    ROUND(MIN(days), 2)             AS min_days,
    ROUND(MAX(days), 2)             AS max_days,
    ROUND(AVG(days), 2)             AS avg_days
FROM days_to_cancel
GROUP BY quintile   
ORDER BY quintile;


-- Cancellation rate by created_at cohort month for US plus subscriptions
--
-- Each row represents a monthly cohort of US plus subscribers (grouped by the
-- month they were created). For each cohort, it shows the total number of
-- subscriptions, how many were eventually cancelled (status='cancelled'), and
-- the cancellation rate. This lets you compare whether older or newer cohorts
-- cancel at higher rates, though recent months should be interpreted cautiously
-- since those subscriptions have had less time to churn.
SELECT
    DATE_TRUNC('month', created_at)                     AS cohort_month,
    COUNT(*)                                            AS total_subscriptions,
    COUNT(*) FILTER (WHERE status = 'cancelled')        AS total_cancelled,
    ROUND(
        COUNT(*) FILTER (WHERE status = 'cancelled') * 100.0 / COUNT(*),
    2)                                                  AS cancellation_rate
FROM subscriptions
WHERE country_code = 'US'
  AND plan = 'plus'
GROUP BY cohort_month
ORDER BY cohort_month;


-- 3-, 6-, and 12-month churn rates by created_at cohort month for US plus subscriptions
--
-- Each row is a monthly cohort of US plus subscribers. For each cohort, it shows
-- what share of subscribers cancelled within 3, 6, and 12 months of their
-- created_at date. Unlike the query above which uses status='cancelled' (a
-- point-in-time label), these rates use cancelled_at to measure time-bounded
-- churn — i.e. did the subscriber actually cancel within N months of signing up?
--
-- Cohorts that haven't yet reached their full window (e.g. a cohort from 8 months
-- ago won't have completed its 12-month window) will show artificially low rates
-- and should be interpreted cautiously.
SELECT
    DATE_TRUNC('month', created_at)                         AS cohort_month,
    COUNT(*)                                                AS total_subscriptions,
    ROUND(
        COUNT(*) FILTER (WHERE cancelled_at <= created_at + INTERVAL '3 months') * 100.0 / COUNT(*),
    2)                                                      AS churn_rate_3m,
    ROUND(
        COUNT(*) FILTER (WHERE cancelled_at <= created_at + INTERVAL '6 months') * 100.0 / COUNT(*),
    2)                                                      AS churn_rate_6m,
    ROUND(
        COUNT(*) FILTER (WHERE cancelled_at <= created_at + INTERVAL '12 months') * 100.0 / COUNT(*),
    2)                                                      AS churn_rate_12m
FROM subscriptions
WHERE country_code = 'US'
  AND plan = 'plus'
GROUP BY cohort_month
ORDER BY cohort_month;


WITH merchant_cohorts AS (
    SELECT
        merchant_id,
        DATE_TRUNC('month', created_at)                            AS cohort_start,
        DATE_TRUNC('month', created_at) + INTERVAL '3 months'     AS cohort_month_3
    FROM merchants
    WHERE DATE_TRUNC('month', created_at) + INTERVAL '3 months' <= DATE_TRUNC('month', CURRENT_DATE)
),

active_at_month_3 AS (
    SELECT DISTINCT mc.merchant_id
    FROM merchant_cohorts AS mc
    INNER JOIN orders AS o
        ON o.merchant_id = mc.merchant_id
        AND DATE_TRUNC('month', o.created_at) = mc.cohort_month_3
        AND o.status = 'completed'
)

SELECT
    TO_CHAR(mc.cohort_start, 'YYYY-MM')                                             AS cohort_month,
    COUNT(DISTINCT mc.merchant_id)                                                   AS cohort_size,
    COUNT(DISTINCT a.merchant_id)                                                    AS active_month_3,
    ROUND(COUNT(DISTINCT a.merchant_id) * 100.0 / COUNT(DISTINCT mc.merchant_id), 1) AS retention_pct
FROM merchant_cohorts AS mc
LEFT JOIN active_at_month_3 AS a
    ON a.merchant_id = mc.merchant_id
GROUP BY mc.cohort_start
ORDER BY mc.cohort_start;


-- Optimized: pre-aggregate orders before joining (opt 3),
-- and use range predicate on created_at for partition pruning (opt 2)
WITH merchant_cohorts AS (
    SELECT
        merchant_id,
        DATE_TRUNC('month', created_at)                            AS cohort_start,
        DATE_TRUNC('month', created_at) + INTERVAL '3 months'     AS cohort_month_3
    FROM merchants
    WHERE DATE_TRUNC('month', created_at) + INTERVAL '3 months' <= DATE_TRUNC('month', CURRENT_DATE)
),

completed_orders_by_month AS (
    SELECT
        merchant_id,
        DATE_TRUNC('month', created_at) AS order_month
    FROM orders
    WHERE status = 'completed'
    GROUP BY merchant_id, DATE_TRUNC('month', created_at)
),

active_at_month_3 AS (
    SELECT DISTINCT mc.merchant_id
    FROM merchant_cohorts AS mc
    INNER JOIN completed_orders_by_month AS co
        ON co.merchant_id = mc.merchant_id
        AND co.order_month >= mc.cohort_month_3
        AND co.order_month < mc.cohort_month_3 + INTERVAL '1 month'
)

SELECT
    TO_CHAR(mc.cohort_start, 'YYYY-MM')                                              AS cohort_month,
    COUNT(DISTINCT mc.merchant_id)                                                    AS cohort_size,
    COUNT(DISTINCT a.merchant_id)                                                     AS active_month_3,
    ROUND(COUNT(DISTINCT a.merchant_id) * 100.0 / COUNT(DISTINCT mc.merchant_id), 1) AS retention_pct
FROM merchant_cohorts AS mc
LEFT JOIN active_at_month_3 AS a
    ON a.merchant_id = mc.merchant_id
GROUP BY mc.cohort_start
ORDER BY mc.cohort_start;




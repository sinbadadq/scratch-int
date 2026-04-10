-- Date granularity
SELECT
    COUNT(*)                                            AS total_rows,
    COUNT(DISTINCT created_at)                          AS distinct_timestamps,
    COUNT(DISTINCT DATE_TRUNC('day', created_at))       AS distinct_days,
    COUNT(DISTINCT DATE_TRUNC('month', created_at))     AS distinct_months,
    COUNT(DISTINCT DATE_TRUNC('year', created_at))      AS distinct_years
FROM orders;

-- Earliest and latest dates
SELECT
    MIN(created_at) AS earliest,
    MAX(created_at) AS latest
FROM orders;

-- Status breakdown
SELECT
    status,
    COUNT(*)                                                AS row_count,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 2)     AS pct
FROM orders
GROUP BY 1
ORDER BY 2 DESC;

-- Null vs not null customer_id
SELECT
    CASE WHEN customer_id IS NULL THEN 'guest' ELSE 'not guest' END   AS customer_id_status,
    COUNT(*)                                                         AS row_count,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 2)              AS pct
FROM orders
GROUP BY 1;

-- Status breakdown by guest vs not guest
SELECT
    CASE WHEN customer_id IS NULL THEN 'guest' ELSE 'not guest' END AS customer_type,
    status,
    COUNT(*)                                                        AS row_count,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (
        PARTITION BY CASE WHEN customer_id IS NULL THEN 'guest' ELSE 'not guest' END
    ), 2)                                                           AS pct_within_type
FROM orders
GROUP BY 1, 2
ORDER BY 1, 3 DESC;


-- Top 5 countries by guest vs not guest
WITH ranked AS (
    SELECT
        CASE WHEN customer_id IS NULL THEN 'guest' ELSE 'not guest' END AS customer_type,
        country_code,
        COUNT(*)                                                        AS row_count,
        ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (
            PARTITION BY CASE WHEN customer_id IS NULL THEN 'guest' ELSE 'not guest' END
        ), 2)                                                           AS pct_within_type,
        ROW_NUMBER() OVER (
            PARTITION BY CASE WHEN customer_id IS NULL THEN 'guest' ELSE 'not guest' END
            ORDER BY COUNT(*) DESC
        )                                                               AS rn
    FROM orders
    GROUP BY 1, 2
)

SELECT
    customer_type,
    country_code,
    row_count,
    pct_within_type
FROM ranked
WHERE rn <= 5
ORDER BY 1, 3 DESC;

-- Status breakdown pivoted by channel
SELECT
    status,
    COUNT(*) FILTER (WHERE channel = 'pos')                                                                                AS "channel-pos-count",
    ROUND(COUNT(*) FILTER (WHERE channel = 'pos') * 100.0    / SUM(COUNT(*) FILTER (WHERE channel = 'pos')) OVER (), 2)    AS "channel-pos-pct",
    COUNT(*) FILTER (WHERE channel = 'online')                                                                             AS "channel-online-count",
    ROUND(COUNT(*) FILTER (WHERE channel = 'online') * 100.0 / SUM(COUNT(*) FILTER (WHERE channel = 'online')) OVER (), 2) AS "channel-online-pct"
FROM orders
GROUP BY 1
ORDER BY 1;

-- Status breakdown where created_at = updated_at
SELECT
    status,
    COUNT(*)                                                AS row_count,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 2)     AS pct
FROM orders
WHERE created_at = updated_at
GROUP BY 1
ORDER BY 2 DESC;


-- Status breakdown where created_at = updated_at for online channel
SELECT
    status,
    COUNT(*)                                                AS row_count,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 2)     AS pct
FROM orders
WHERE created_at = updated_at
    AND channel = 'online'
GROUP BY 1, 2
ORDER BY 2 DESC;

-- Status breakdown where created_at = updated_at for pos channel
SELECT
    status,
    COUNT(*)                                                AS row_count,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 2)     AS pct
FROM orders
WHERE created_at = updated_at
    AND channel = 'pos'
GROUP BY 1, 2
ORDER BY 2 DESC;

-- Cancellation rate by month and channel
SELECT
    DATE_TRUNC('month', created_at)                                                                                             AS month,
    ROUND(COUNT(*) FILTER (WHERE channel = 'pos'    AND status = 'cancelled') * 100.0 / COUNT(*) FILTER (WHERE channel = 'pos'),    2) AS pos_cancel_rate,
    ROUND(COUNT(*) FILTER (WHERE channel = 'online' AND status = 'cancelled') * 100.0 / COUNT(*) FILTER (WHERE channel = 'online'), 2) AS online_cancel_rate
FROM orders
GROUP BY 1
ORDER BY 1;

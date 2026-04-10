WITH months AS (
    SELECT DISTINCT month FROM date_dimension
),
monthly_revenue_lost AS (
    SELECT
        m.month,
        SUM(t.monthly_price) AS revenue_lost
    FROM months m
    INNER JOIN shop_theme_installs sti
        ON sti.valid_from  < m.month + INTERVAL '1 month'
        AND (sti.valid_to IS NULL OR sti.valid_to > m.month)
    INNER JOIN pirated_themes pt ON sti.theme_id = pt.theme_id
    INNER JOIN themes t          ON sti.theme_id = t.theme_id
    GROUP BY m.month
)
SELECT
    month,
    revenue_lost,
    SUM(revenue_lost) OVER (ORDER BY month) AS cumulative_revenue_lost
FROM monthly_revenue_lost
ORDER BY month;

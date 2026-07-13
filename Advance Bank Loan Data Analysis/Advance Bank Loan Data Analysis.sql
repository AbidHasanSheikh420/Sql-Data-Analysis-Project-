/* 
   ANALYSIS ENGINE: 
   This script covers Temporal, Regional, and Categorical deep-dives.
*/

-- 1. WINDOW FUNCTIONS: Calculate Rolling Averages (Replaces 50+ simple aggregate queries)
SELECT 
    region, 
    order_date, 
    delivery_time_days,
    AVG(delivery_time_days) OVER (
        PARTITION BY region 
        ORDER BY order_date 
        ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
    ) AS rolling_avg_7day_delay
FROM supply_chain_data;

-- 2. CTES: Complex Segmentation (Replaces 100+ filtering queries)
WITH MonthlyPerformance AS (
    SELECT 
        region, 
        EXTRACT(MONTH FROM order_date) as month,
        SUM(shipping_cost) as total_cost
    FROM supply_chain_data
    GROUP BY region, month
)
SELECT 
    region, 
    month, 
    total_cost,
    LAG(total_cost) OVER (PARTITION BY region ORDER BY month) as prev_month_cost
FROM MonthlyPerformance;

-- 3. CONDITIONAL AGGREGATION: Risk Profiling (Replaces 150+ status-check queries)
SELECT 
    product_category,
    COUNT(CASE WHEN delivery_time_days > 10 THEN 1 END) as high_risk_count,
    COUNT(CASE WHEN delivery_time_days <= 10 THEN 1 END) as low_risk_count,
    ROUND(AVG(shipping_cost), 2) as avg_cost
FROM supply_chain_data
GROUP BY product_category
HAVING AVG(delivery_time_days) > 5;
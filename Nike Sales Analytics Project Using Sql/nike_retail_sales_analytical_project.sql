-- =========================================================================
-- PROJECT: Nike Retail Sales Enterprise Analytical & BI Database Project
-- DATA SOURCE REFERENCE: image_3fae9c.jpg (Nike US Retail Sales Dataset)
-- DATABASE COMPATIBILITY: PostgreSQL / MySQL / Standard ANSI SQL
-- AUTHOR: SQL Analytics Expert
-- PURPOSE: End-to-end analytical project containing schema design, ETL validation,
--          and comprehensive analytical queries from basic to highly advanced levels.
-- =========================================================================

-- =========================================================================
-- SECTION 1: DATABASE SETUP, SCHEMA DESIGN & INTEGRITY CONSTRAINTS
-- =========================================================================

-- Drop tables if they exist to ensure clean redeployment
DROP TABLE IF EXISTS sales_performance_metrics;
DROP TABLE IF EXISTS nike_sales_staging;
DROP TABLE IF EXISTS products;
DROP TABLE IF EXISTS retailers;
DROP TABLE IF EXISTS geography;

-- Create Geography Master Table
CREATE TABLE geography (
    geography_id SERIAL PRIMARY KEY,
    region VARCHAR(50) NOT NULL,
    state VARCHAR(50) NOT NULL,
    city VARCHAR(50) NOT NULL,
    CONSTRAINT uniq_geo UNIQUE (region, state, city)
);

-- Create Retailers Master Table
CREATE TABLE retailers (
    retailer_id VARCHAR(50) PRIMARY KEY,
    retailer_name VARCHAR(100) NOT NULL,
    sales_method VARCHAR(50) NOT NULL CHECK (sales_method IN ('In-store', 'Outlet', 'Online'))
);

-- Create Products Master Table
CREATE TABLE products (
    product_id SERIAL PRIMARY KEY,
    product_name VARCHAR(150) NOT NULL UNIQUE,
    category VARCHAR(100) NOT NULL
);

-- Create Centralized Nike Sales Transaction Table
CREATE TABLE nike_sales_staging (
    transaction_id SERIAL PRIMARY KEY,
    retailer_id VARCHAR(50) REFERENCES retailers(retailer_id),
    geography_id INT REFERENCES geography(geography_id),
    product_id INT REFERENCES products(product_id),
    invoice_date DATE NOT NULL,
    price_per_unit NUMERIC(10, 2) NOT NULL CHECK (price_per_unit >= 0),
    units_sold INT NOT NULL CHECK (units_sold >= 0),
    total_sales NUMERIC(15, 2) GENERATED ALWAYS AS (price_per_unit * units_sold) STORED,
    operating_profit NUMERIC(15, 2) NOT NULL,
    operating_margin NUMERIC(5, 4) NOT NULL CHECK (operating_margin >= 0 AND operating_margin <= 1)
);

-- =========================================================================
-- SECTION 2: METADATA & DATA QUALITY ASSURANCE (ETL & CLEANING QUERIES)
-- =========================================================================

-- Query 1: Find any records with missing critical fields
SELECT COUNT(*) AS missing_critical_data
FROM nike_sales_staging
WHERE retailer_id IS NULL 
   OR geography_id IS NULL 
   OR product_id IS NULL 
   OR invoice_date IS NULL;

-- Query 2: Check for logical inconsistencies where profit is greater than sales
SELECT transaction_id, total_sales, operating_profit 
FROM nike_sales_staging 
WHERE operating_profit > total_sales;

-- Query 3: Validate that calculated margin aligns with stored operating profit
-- Margin Equation: Operating Margin = Operating Profit / Total Sales
SELECT transaction_id, total_sales, operating_profit, operating_margin,
       ABS(operating_margin - (operating_profit / NULLIF(total_sales, 0))) AS margin_variance
FROM nike_sales_staging
WHERE ABS(operating_margin - (operating_profit / NULLIF(total_sales, 0))) > 0.01;

-- Query 4: Identify outlier transactions with extremely high price per unit (> 3x standard deviation)
WITH price_stats AS (
    SELECT AVG(price_per_unit) AS avg_price, STDDEV(price_per_unit) AS std_price
    FROM nike_sales_staging
)
SELECT t.transaction_id, t.price_per_unit, p.product_name
FROM nike_sales_staging t
JOIN products p ON t.product_id = p.product_id
CROSS JOIN price_stats s
WHERE t.price_per_unit > (s.avg_price + (3 * s.std_price));

-- Query 5: Identify records with duplicate transaction entries based on unique dimensions
SELECT retailer_id, geography_id, product_id, invoice_date, units_sold, COUNT(*)
FROM nike_sales_staging
GROUP BY retailer_id, geography_id, product_id, invoice_date, units_sold
HAVING COUNT(*) > 1;


-- =========================================================================
-- SECTION 3: EXPLORATORY DATA ANALYSIS & BASIC AGGREGATIONS
-- =========================================================================

-- Query 6: Total overall revenue and profit generated across the entire dataset
SELECT 
    SUM(total_sales) AS gross_sales, 
    SUM(operating_profit) AS gross_profit,
    AVG(operating_margin) * 100 AS average_operating_margin
FROM nike_sales_staging;

-- Query 7: Total distinct products, retailers, regions, and states present
SELECT 
    (SELECT COUNT(DISTINCT product_id) FROM products) AS unique_products,
    (SELECT COUNT(DISTINCT retailer_id) FROM retailers) AS unique_retailers,
    (SELECT COUNT(DISTINCT region) FROM geography) AS unique_regions,
    (SELECT COUNT(DISTINCT state) FROM geography) AS unique_states;

-- Query 8: Min, Max, and Average product unit price
SELECT 
    MIN(price_per_unit) AS lowest_price,
    MAX(price_per_unit) AS highest_price,
    AVG(price_per_unit) AS average_price
FROM nike_sales_staging;

-- Query 9: Transaction volumes grouped by Year of purchase
SELECT 
    EXTRACT(YEAR FROM invoice_date) AS sales_year,
    COUNT(*) AS total_transactions,
    SUM(units_sold) AS total_units_sold
FROM nike_sales_staging
GROUP BY EXTRACT(YEAR FROM invoice_date)
ORDER BY sales_year;

-- Query 10: Top 5 products by total units sold
SELECT p.product_name, SUM(t.units_sold) AS total_units
FROM nike_sales_staging t
JOIN products p ON t.product_id = p.product_id
GROUP BY p.product_name
ORDER BY total_units DESC
LIMIT 5;

-- Query 11: Distribution of transactions across different sales methods
SELECT r.sales_method, COUNT(*) AS transaction_count, SUM(t.total_sales) AS method_revenue
FROM nike_sales_staging t
JOIN retailers r ON t.retailer_id = r.retailer_id
GROUP BY r.sales_method
ORDER BY method_revenue DESC;

-- Query 12: Monthly transactional baseline volume (identifying season variations)
SELECT 
    EXTRACT(MONTH FROM invoice_date) AS sales_month,
    COUNT(*) AS total_transactions
FROM nike_sales_staging
GROUP BY EXTRACT(MONTH FROM invoice_date)
ORDER BY sales_month;

-- Query 13: Analysis of top 5 geographic states by average product pricing
SELECT g.state, AVG(t.price_per_unit) AS average_state_price
FROM nike_sales_staging t
JOIN geography g ON t.geography_id = g.geography_id
GROUP BY g.state
ORDER BY average_state_price DESC
LIMIT 5;

-- Query 14: Analyze maximum orders and single ticket revenue peaks
SELECT MAX(total_sales) AS maximum_ticket_sales, MAX(units_sold) AS maximum_units_per_order
FROM nike_sales_staging;

-- Query 15: Identify retailers with zero active transactions
SELECT r.retailer_id, r.retailer_name
FROM retailers r
LEFT JOIN nike_sales_staging t ON r.retailer_id = t.retailer_id
WHERE t.transaction_id IS NULL;


-- =========================================================================
-- SECTION 4: INTERMEDIATE BUSINESS PERFORMANCE QUESTIONS
-- =========================================================================

-- Query 16: Top 5 performing state-product categories by Operating Profit
SELECT g.state, p.category, SUM(t.operating_profit) AS total_profit
FROM nike_sales_staging t
JOIN geography g ON t.geography_id = g.geography_id
JOIN products p ON t.product_id = p.product_id
GROUP BY g.state, p.category
ORDER BY total_profit DESC
LIMIT 5;

-- Query 17: Average profit margin per retailer name ordered by efficiency
SELECT r.retailer_name, AVG(t.operating_margin) * 100 AS average_margin_percentage
FROM nike_sales_staging t
JOIN retailers r ON t.retailer_id = r.retailer_id
GROUP BY r.retailer_name
ORDER BY average_margin_percentage DESC;

-- Query 18: Quarterly revenue breakdown across all products
SELECT 
    EXTRACT(YEAR FROM t.invoice_date) AS sales_year,
    EXTRACT(QUARTER FROM t.invoice_date) AS sales_quarter,
    p.product_name,
    SUM(t.total_sales) AS quarterly_revenue
FROM nike_sales_staging t
JOIN products p ON t.product_id = p.product_id
GROUP BY EXTRACT(YEAR FROM t.invoice_date), EXTRACT(QUARTER FROM t.invoice_date), p.product_name
ORDER BY sales_year, sales_quarter, quarterly_revenue DESC;

-- Query 19: Geographic analysis highlighting sales variance by region and product group
SELECT g.region, p.category, SUM(t.total_sales) AS total_sales_volume
FROM nike_sales_staging t
JOIN geography g ON t.geography_id = g.geography_id
JOIN products p ON t.product_id = p.product_id
GROUP BY g.region, p.category
ORDER BY g.region, total_sales_volume DESC;

-- Query 20: Performance metrics comparison of "Online" vs "In-Store" sales across seasons
-- Spring (Mar-May), Summer (Jun-Aug), Autumn (Sep-Nov), Winter (Dec-Feb)
SELECT 
    CASE 
        WHEN EXTRACT(MONTH FROM t.invoice_date) IN (3,4,5) THEN 'Spring'
        WHEN EXTRACT(MONTH FROM t.invoice_date) IN (6,7,8) THEN 'Summer'
        WHEN EXTRACT(MONTH FROM t.invoice_date) IN (9,10,11) THEN 'Autumn'
        ELSE 'Winter'
    END AS season,
    r.sales_method,
    SUM(t.total_sales) AS aggregate_revenue,
    SUM(t.operating_profit) AS aggregate_profit
FROM nike_sales_staging t
JOIN retailers r ON t.retailer_id = r.retailer_id
GROUP BY 1, r.sales_method
ORDER BY season, aggregate_revenue DESC;

-- Query 21: High value transactions threshold analyzer (orders where sales > $15,000)
SELECT t.transaction_id, r.retailer_name, p.product_name, t.total_sales
FROM nike_sales_staging t
JOIN retailers r ON t.retailer_id = r.retailer_id
JOIN products p ON t.product_id = p.product_id
WHERE t.total_sales > 15000.00
ORDER BY t.total_sales DESC;

-- Query 22: Identifying performance gap - lowest 5 cities by product sales conversion
SELECT g.city, g.state, SUM(t.total_sales) AS cumulative_sales
FROM nike_sales_staging t
JOIN geography g ON t.geography_id = g.geography_id
GROUP BY g.city, g.state
ORDER BY cumulative_sales ASC
LIMIT 5;

-- Query 23: Monthly growth index metrics - raw revenue and units sold
SELECT 
    DATE_TRUNC('month', t.invoice_date) AS sales_month,
    SUM(t.total_sales) AS monthly_revenue,
    SUM(t.units_sold) AS monthly_units
FROM nike_sales_staging t
GROUP BY DATE_TRUNC('month', t.invoice_date)
ORDER BY sales_month;

-- Query 24: Total product count and average profit per physical retailer location
SELECT r.retailer_name, g.state, COUNT(DISTINCT t.product_id) AS distinct_products_sold, AVG(t.operating_profit) AS avg_profit
FROM nike_sales_staging t
JOIN retailers r ON t.retailer_id = r.retailer_id
JOIN geography g ON t.geography_id = g.geography_id
GROUP BY r.retailer_name, g.state
ORDER BY avg_profit DESC;

-- Query 25: Identifying top transaction days (where aggregate revenue exceeded 100k)
SELECT t.invoice_date, SUM(t.total_sales) AS daily_sales
FROM nike_sales_staging t
GROUP BY t.invoice_date
HAVING SUM(t.total_sales) > 100000.00
ORDER BY daily_sales DESC;


-- =========================================================================
-- SECTION 5: ADVANCED WINDOW FUNCTIONS & ANALYTICAL REPORTING
-- =========================================================================

-- Query 26: Cumulative running total of sales partitioned by product category over time
SELECT 
    t.invoice_date,
    p.category,
    t.total_sales,
    SUM(t.total_sales) OVER(PARTITION BY p.category ORDER BY t.invoice_date ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS running_total_sales
FROM nike_sales_staging t
JOIN products p ON t.product_id = p.product_id
ORDER BY p.category, t.invoice_date;

-- Query 27: Rank products within each state based on units sold
SELECT 
    g.state,
    p.product_name,
    SUM(t.units_sold) AS total_units,
    DENSE_RANK() OVER(PARTITION BY g.state ORDER BY SUM(t.units_sold) DESC) AS rank_in_state
FROM nike_sales_staging t
JOIN geography g ON t.geography_id = g.geography_id
JOIN products p ON t.product_id = p.product_id
GROUP BY g.state, p.product_name;

-- Query 28: Month-over-Month (MoM) Growth percentage of revenue
WITH monthly_revenue_cte AS (
    SELECT 
        DATE_TRUNC('month', invoice_date) AS sales_month,
        SUM(total_sales) AS current_month_sales
    FROM nike_sales_staging
    GROUP BY DATE_TRUNC('month', invoice_date)
)
SELECT 
    sales_month,
    current_month_sales,
    LAG(current_month_sales, 1) OVER (ORDER BY sales_month) AS previous_month_sales,
    (current_month_sales - LAG(current_month_sales, 1) OVER (ORDER BY sales_month)) / 
        NULLIF(LAG(current_month_sales, 1) OVER (ORDER BY sales_month), 0) * 100 AS mom_growth_pct
FROM monthly_revenue_cte
ORDER BY sales_month;

-- Query 29: Find top 3 cities per region based on total revenue using analytical partitions
WITH ranked_cities AS (
    SELECT 
        g.region,
        g.city,
        SUM(t.total_sales) AS total_sales,
        ROW_NUMBER() OVER(PARTITION BY g.region ORDER BY SUM(t.total_sales) DESC) AS city_rank
    FROM nike_sales_staging t
    JOIN geography g ON t.geography_id = g.geography_id
    GROUP BY g.region, g.city
)
SELECT region, city, total_sales, city_rank
FROM ranked_cities
WHERE city_rank <= 3;

-- Query 30: Moving average of units sold over a trailing 7-day window
SELECT 
    invoice_date,
    SUM(units_sold) AS daily_units_sold,
    AVG(SUM(units_sold)) OVER(ORDER BY invoice_date ROWS BETWEEN 6 PRECEDING AND CURRENT ROW) AS rolling_7day_avg_units
FROM nike_sales_staging
GROUP BY invoice_date
ORDER BY invoice_date;

-- Query 31: Year-over-Year (YoY) Sales Comparison across Product Categories
WITH annual_category_sales AS (
    SELECT 
        EXTRACT(YEAR FROM t.invoice_date) AS sales_year,
        p.category,
        SUM(t.total_sales) AS yearly_sales
    FROM nike_sales_staging t
    JOIN products p ON t.product_id = p.product_id
    GROUP BY EXTRACT(YEAR FROM t.invoice_date), p.category
)
SELECT 
    sales_year,
    category,
    yearly_sales,
    LAG(yearly_sales, 1) OVER(PARTITION BY category ORDER BY sales_year) AS prior_year_sales,
    (yearly_sales - LAG(yearly_sales, 1) OVER(PARTITION BY category ORDER BY sales_year)) /
        NULLIF(LAG(yearly_sales, 1) OVER(PARTITION BY category ORDER BY sales_year), 0) * 100 AS yoy_growth_rate
FROM annual_category_sales
ORDER BY category, sales_year;

-- Query 32: Percent of total regional sales generated by each specific retailer
SELECT 
    g.region,
    r.retailer_name,
    SUM(t.total_sales) AS retailer_regional_sales,
    SUM(SUM(t.total_sales)) OVER(PARTITION BY g.region) AS total_regional_sales,
    (SUM(t.total_sales) / SUM(SUM(t.total_sales)) OVER(PARTITION BY g.region)) * 100 AS regional_contribution_pct
FROM nike_sales_staging t
JOIN geography g ON t.geography_id = g.geography_id
JOIN retailers r ON t.retailer_id = r.retailer_id
GROUP BY g.region, r.retailer_name
ORDER BY g.region, regional_contribution_pct DESC;

-- Query 33: Difference between individual unit price and the product line average
SELECT 
    t.transaction_id,
    p.product_name,
    t.price_per_unit,
    AVG(t.price_per_unit) OVER(PARTITION BY p.product_id) AS average_product_line_price,
    (t.price_per_unit - AVG(t.price_per_unit) OVER(PARTITION BY p.product_id)) AS price_divergence
FROM nike_sales_staging t
JOIN products p ON t.product_id = p.product_id;

-- Query 34: Determine quartile distribution of transactions based on quantity sold
SELECT 
    transaction_id,
    units_sold,
    NTILE(4) OVER (ORDER BY units_sold) AS quantity_quartile
FROM nike_sales_staging;

-- Query 35: Standardized performance classification relative to regional sales average
WITH regional_bounds AS (
    SELECT 
        g.region,
        AVG(t.total_sales) AS avg_sales,
        STDDEV(t.total_sales) AS std_sales
    FROM nike_sales_staging t
    JOIN geography g ON t.geography_id = g.geography_id
    GROUP BY g.region
)
SELECT 
    t.transaction_id,
    g.region,
    t.total_sales,
    r.avg_sales,
    CASE 
        WHEN t.total_sales > (r.avg_sales + r.std_sales) THEN 'Outperforming Tier'
        WHEN t.total_sales < (r.avg_sales - r.std_sales) THEN 'Underperforming Tier'
        ELSE 'Neutral baseline'
    END AS performance_grade
FROM nike_sales_staging t
JOIN geography g ON t.geography_id = g.geography_id
JOIN regional_bounds r ON g.region = r.region;


-- =========================================================================
-- SECTION 6: COHORT ANALYSIS & CUSTOMER/RETAILER BEHAVIOR SEGMENTATION
-- =========================================================================

-- Query 36: RFM (Recency, Frequency, Monetary) Customer/Retailer Segment Scoring
-- Calculates how recently, how frequently, and how much value each retailer provides
WITH rfm_raw_metrics AS (
    SELECT 
        retailer_id,
        MAX(invoice_date) AS last_active_date,
        COUNT(transaction_id) AS total_orders,
        SUM(total_sales) AS cumulative_spend
    FROM nike_sales_staging
    GROUP BY retailer_id
),
rfm_scores AS (
    SELECT 
        retailer_id,
        last_active_date,
        -- Recency: Higher score for more recent activity (using mock anchor date 2026-07-15)
        NTILE(4) OVER (ORDER BY last_active_date ASC) AS recency_score,
        -- Frequency: Higher score for higher number of transactions
        NTILE(4) OVER (ORDER BY total_orders DESC) AS frequency_score,
        -- Monetary: Higher score for greater cumulative sales volume
        NTILE(4) OVER (ORDER BY cumulative_spend DESC) AS monetary_score
    FROM rfm_raw_metrics
)
SELECT 
    r.retailer_id,
    ret.retailer_name,
    r.last_active_date,
    r.recency_score,
    r.frequency_score,
    r.monetary_score,
    (r.recency_score + r.frequency_score + r.monetary_score) AS comprehensive_rfm_index,
    CASE 
        WHEN (r.recency_score + r.frequency_score + r.monetary_score) >= 10 THEN 'Elite Key Partner'
        WHEN (r.recency_score + r.frequency_score + r.monetary_score) >= 7 THEN 'Mid-Market Regular'
        ELSE 'Hibernating / High Risk'
    END AS priority_tier
FROM rfm_scores r
JOIN retailers ret ON r.retailer_id = ret.retailer_id
ORDER BY comprehensive_rfm_index DESC;

-- Query 37: Cohort grouping of retailers by their activation quarter
WITH retailer_first_active AS (
    SELECT 
        retailer_id,
        DATE_TRUNC('quarter', MIN(invoice_date)) AS cohort_quarter
    FROM nike_sales_staging
    GROUP BY retailer_id
)
SELECT 
    cohort_quarter,
    COUNT(DISTINCT retailer_id) AS cohort_size
FROM retailer_first_active
GROUP BY cohort_quarter
ORDER BY cohort_quarter;

-- Query 38: Analysis of channel synergy (online vs offline balance) per retailer
SELECT 
    r.retailer_name,
    SUM(CASE WHEN r.sales_method = 'Online' THEN t.total_sales ELSE 0 END) AS online_sales,
    SUM(CASE WHEN r.sales_method IN ('In-store', 'Outlet') THEN t.total_sales ELSE 0 END) AS offline_sales,
    (SUM(CASE WHEN r.sales_method = 'Online' THEN t.total_sales ELSE 0 END) / NULLIF(SUM(t.total_sales), 0)) * 100 AS digital_mix_percentage
FROM nike_sales_staging t
JOIN retailers r ON t.retailer_id = r.retailer_id
GROUP BY r.retailer_name
ORDER BY digital_mix_percentage DESC;

-- Query 39: Cumulative percentage share of total company sales generated by each product line (ABC Analysis)
WITH product_abc_class AS (
    SELECT 
        p.product_name,
        SUM(t.total_sales) AS product_revenue,
        SUM(SUM(t.total_sales)) OVER() AS enterprise_revenue,
        SUM(SUM(t.total_sales)) OVER(ORDER BY SUM(t.total_sales) DESC ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS running_revenue_sum
    FROM nike_sales_staging t
    JOIN products p ON t.product_id = p.product_id
    GROUP BY p.product_name
)
SELECT 
    product_name,
    product_revenue,
    (product_revenue / enterprise_revenue) * 100 AS revenue_percentage,
    (running_revenue_sum / enterprise_revenue) * 100 AS cumulative_percentage,
    CASE 
        WHEN (running_revenue_sum / enterprise_revenue) * 100 <= 70.00 THEN 'Class A (Core Engine)'
        WHEN (running_revenue_sum / enterprise_revenue) * 100 <= 90.00 THEN 'Class B (Value Add)'
        ELSE 'Class C (Tail Ends)'
    END AS inventory_abc_classification
FROM product_abc_class;

-- Query 40: Customer geographic migration (finding retailers active in multiple regions)
SELECT r.retailer_name, COUNT(DISTINCT g.region) AS active_regions_count
FROM nike_sales_staging t
JOIN retailers r ON t.retailer_id = r.retailer_id
JOIN geography g ON t.geography_id = g.geography_id
GROUP BY r.retailer_name
HAVING COUNT(DISTINCT g.region) > 1
ORDER BY active_regions_count DESC;


-- =========================================================================
-- SECTION 7: PROCEDURES, VIEWS, TRIGGERS & HIGH PERFORMANCE TUNING
-- =========================================================================

-- Creating a materialized view for highly accessible analytics reporting
CREATE MATERIALIZED VIEW mv_nike_global_performance AS
SELECT 
    g.region,
    g.state,
    p.category,
    p.product_name,
    SUM(t.total_sales) AS total_revenue,
    SUM(t.operating_profit) AS aggregate_profit,
    SUM(t.units_sold) AS aggregate_units_sold,
    AVG(t.operating_margin) AS mean_operating_margin
FROM nike_sales_staging t
JOIN geography g ON t.geography_id = g.geography_id
JOIN products p ON t.product_id = p.product_id
GROUP BY g.region, g.state, p.category, p.product_name;

-- Indexes targeting optimization for time-series and geographic joins
CREATE INDEX idx_sales_invoice_date ON nike_sales_staging(invoice_date);
CREATE INDEX idx_sales_geo_product ON nike_sales_staging(geography_id, product_id);
CREATE INDEX idx_sales_retailer ON nike_sales_staging(retailer_id);

-- Query 41: Auto refreshing reporting view mechanism (Demonstrated as clean analytical selection)
-- REFRESH MATERIALIZED VIEW mv_nike_global_performance;
SELECT * 
FROM mv_nike_global_performance 
WHERE region = 'Northeast' AND total_revenue > 50000.00;

-- Query 42: Audit Trigger function to log database alterations for security and pipeline integrity
CREATE TABLE data_pipeline_audit_log (
    audit_id SERIAL PRIMARY KEY,
    action_performed VARCHAR(50),
    executed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    affected_rows INT
);

-- Trigger definition tracking pipeline changes
CREATE OR REPLACE FUNCTION log_sales_changes()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO data_pipeline_audit_log (action_performed, affected_rows)
    VALUES ('DML Operation on Sales Staging', 1);
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_audit_sales_table
AFTER INSERT OR UPDATE OR DELETE ON nike_sales_staging
FOR EACH ROW
EXECUTE FUNCTION log_sales_changes();


-- =========================================================================
-- SECTION 8: EXHAUSTIVE BUSINESS INTELLIGENCE DEPTH QUERY SUITE
-- =========================================================================

-- Query 43: Analyzing top 5 product category margins relative to the global average margin
SELECT 
    p.category,
    AVG(t.operating_margin) AS category_avg_margin,
    (SELECT AVG(operating_margin) FROM nike_sales_staging) AS global_avg_margin,
    (AVG(t.operating_margin) - (SELECT AVG(operating_margin) FROM nike_sales_staging)) AS margin_delta
FROM nike_sales_staging t
JOIN products p ON t.product_id = p.product_id
GROUP BY p.category
ORDER BY category_avg_margin DESC;

-- Query 44: Find the weeks with the highest volatility (variance) in units sold
SELECT 
    DATE_TRUNC('week', invoice_date) AS sales_week,
    VARIANCE(units_sold) AS volume_variance,
    STDDEV(units_sold) AS volume_std_dev
FROM nike_sales_staging
GROUP BY DATE_TRUNC('week', invoice_date)
HAVING COUNT(*) > 5
ORDER BY volume_variance DESC
LIMIT 5;

-- Query 45: Geographic concentration of sales - identify cities capturing > 5% of total national revenue
WITH national_sales AS (
    SELECT SUM(total_sales) AS national_total
    FROM nike_sales_staging
)
SELECT 
    g.city,
    g.state,
    SUM(t.total_sales) AS city_total,
    (SUM(t.total_sales) / (SELECT national_total FROM national_sales)) * 100 AS national_revenue_share_pct
FROM nike_sales_staging t
JOIN geography g ON t.geography_id = g.geography_id
GROUP BY g.city, g.state
HAVING (SUM(t.total_sales) / (SELECT national_total FROM national_sales)) * 100 > 5.00
ORDER BY city_total DESC;

-- Query 46: Tracking retailer product portfolio diversification indices
SELECT 
    r.retailer_name,
    COUNT(DISTINCT p.category) AS distinct_categories_offered,
    COUNT(DISTINCT t.product_id) AS distinct_sku_offered
FROM nike_sales_staging t
JOIN retailers r ON t.retailer_id = r.retailer_id
JOIN products p ON t.product_id = p.product_id
GROUP BY r.retailer_name
ORDER BY distinct_sku_offered DESC;

-- Query 47: Monthly Sales Target Tracker (Assuming dynamic monthly target of $200k)
SELECT 
    DATE_TRUNC('month', invoice_date) AS sales_month,
    SUM(total_sales) AS actual_revenue,
    200000.00 AS target_revenue,
    (SUM(total_sales) - 200000.00) AS target_variance,
    CASE 
        WHEN SUM(total_sales) >= 200000.00 THEN 'TARGET MET 🎉'
        ELSE 'UNDERPERFORMING ⚠️'
    END AS monthly_sales_status
FROM nike_sales_staging
GROUP BY DATE_TRUNC('month', invoice_date)
ORDER BY sales_month;

-- Query 48: Identifying structural pricing shifts over months
SELECT 
    p.product_name,
    DATE_TRUNC('month', t.invoice_date) AS sales_month,
    AVG(t.price_per_unit) AS avg_unit_price
FROM nike_sales_staging t
JOIN products p ON t.product_id = p.product_id
GROUP BY p.product_name, DATE_TRUNC('month', t.invoice_date)
ORDER BY p.product_name, sales_month;

-- Query 49: Calculating top 5 peak periods (date range) with greatest aggregate product revenue density
SELECT 
    invoice_date,
    SUM(total_sales) AS daily_aggregate_revenue
FROM nike_sales_staging
GROUP BY invoice_date
ORDER BY daily_aggregate_revenue DESC
LIMIT 5;

-- Query 50: Final comprehensive breakdown - summarizing operational efficiency across states
SELECT 
    g.state,
    SUM(t.units_sold) AS aggregate_units,
    SUM(t.total_sales) AS total_revenue,
    SUM(t.operating_profit) AS aggregate_profit,
    (SUM(t.operating_profit) / NULLIF(SUM(t.total_sales), 0)) * 100 AS realized_operational_efficiency_margin
FROM nike_sales_staging t
JOIN geography g ON t.geography_id = g.geography_id
GROUP BY g.state
ORDER BY realized_operational_efficiency_margin DESC;
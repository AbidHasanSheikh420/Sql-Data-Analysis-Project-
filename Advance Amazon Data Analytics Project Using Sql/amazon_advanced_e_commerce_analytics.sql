/* ==============================================================================
   PROJECT: Amazon Advanced E-Commerce Data Analytics Portfolio
   ROLE: Data Analyst / Data Engineer
   GOAL: Demonstrate advanced SQL proficiency (CTEs, Window Functions, 
         Time-Series, Cohort Analysis, Market Basket Analysis, RFM Modeling)
============================================================================== */

-- ==============================================================================
-- PART 1: DDL (DATA DEFINITION LANGUAGE) & SCHEMA SETUP
-- Creating a normalized relational database representing Amazon's core operations.
-- ==============================================================================

CREATE TABLE Customers (
    customer_id VARCHAR(20) PRIMARY KEY,
    first_name VARCHAR(50),
    last_name VARCHAR(50),
    segment VARCHAR(50),
    city VARCHAR(100),
    state VARCHAR(100),
    country VARCHAR(100),
    postal_code VARCHAR(20),
    account_creation_date DATE
);

CREATE TABLE Sellers (
    seller_id VARCHAR(20) PRIMARY KEY,
    seller_name VARCHAR(100),
    seller_rating DECIMAL(3,2),
    region VARCHAR(50)
);

CREATE TABLE Products (
    product_id VARCHAR(20) PRIMARY KEY,
    product_name VARCHAR(255),
    category VARCHAR(100),
    sub_category VARCHAR(100),
    brand VARCHAR(100),
    unit_cost DECIMAL(10,2),
    unit_price DECIMAL(10,2),
    seller_id VARCHAR(20),
    FOREIGN KEY (seller_id) REFERENCES Sellers(seller_id)
);

CREATE TABLE Orders (
    order_id VARCHAR(20) PRIMARY KEY,
    customer_id VARCHAR(20),
    order_date DATE,
    ship_date DATE,
    ship_mode VARCHAR(50),
    order_status VARCHAR(50),
    FOREIGN KEY (customer_id) REFERENCES Customers(customer_id)
);

CREATE TABLE Order_Items (
    order_item_id VARCHAR(20) PRIMARY KEY,
    order_id VARCHAR(20),
    product_id VARCHAR(20),
    quantity INT,
    discount DECIMAL(4,2),
    total_sales DECIMAL(10,2),
    FOREIGN KEY (order_id) REFERENCES Orders(order_id),
    FOREIGN KEY (product_id) REFERENCES Products(product_id)
);

-- ==============================================================================
-- PART 2: EXPLORATORY DATA ANALYSIS (EDA) & BASIC METRICS
-- Demonstrating foundational grouping, filtering, and aggregation.
-- ==============================================================================

-- Q1: Total Revenue and Profit Margin by Category
SELECT 
    p.category,
    SUM(oi.total_sales) as total_revenue,
    SUM(oi.total_sales - (p.unit_cost * oi.quantity)) as total_profit,
    (SUM(oi.total_sales - (p.unit_cost * oi.quantity)) / SUM(oi.total_sales)) * 100 as profit_margin_pct
FROM Order_Items oi
JOIN Products p ON oi.product_id = p.product_id
GROUP BY p.category
ORDER BY total_revenue DESC;

-- Q2: Top 10 States by Customer Acquisition (Year 2023)
SELECT 
    state, 
    COUNT(customer_id) as new_customers
FROM Customers
WHERE EXTRACT(YEAR FROM account_creation_date) = 2023
GROUP BY state
ORDER BY new_customers DESC
LIMIT 10;

-- Q3: Average Shipping Delay by Shipping Mode
SELECT 
    ship_mode,
    AVG(EXTRACT(DAY FROM (ship_date - order_date))) as avg_days_to_ship,
    MAX(EXTRACT(DAY FROM (ship_date - order_date))) as max_delay
FROM Orders
WHERE order_status = 'Delivered'
GROUP BY ship_mode;

-- ==============================================================================
-- PART 3: ADVANCED WINDOW FUNCTIONS (Crucial for Interviews)
-- ==============================================================================

-- Q4: Top 3 Best-Selling Products in Each Category (Using DENSE_RANK)
WITH RankedProducts AS (
    SELECT 
        p.category,
        p.product_name,
        SUM(oi.total_sales) as total_revenue,
        DENSE_RANK() OVER (PARTITION BY p.category ORDER BY SUM(oi.total_sales) DESC) as sales_rank
    FROM Order_Items oi
    JOIN Products p ON oi.product_id = p.product_id
    GROUP BY p.category, p.product_name
)
SELECT * FROM RankedProducts WHERE sales_rank <= 3;

-- Q5: Year-over-Year (YoY) Monthly Revenue Growth (Using LAG)
WITH MonthlyRevenue AS (
    SELECT 
        DATE_TRUNC('month', order_date) as order_month,
        SUM(total_sales) as revenue
    FROM Orders o
    JOIN Order_Items oi ON o.order_id = oi.order_id
    GROUP BY 1
),
RevenueWithLag AS (
    SELECT 
        order_month,
        revenue,
        LAG(revenue, 12) OVER (ORDER BY order_month) as prev_year_revenue
    FROM MonthlyRevenue
)
SELECT 
    order_month,
    revenue,
    prev_year_revenue,
    CASE 
        WHEN prev_year_revenue IS NULL THEN NULL 
        ELSE ((revenue - prev_year_revenue) / prev_year_revenue) * 100 
    END as yoy_growth_pct
FROM RevenueWithLag;

-- Q6: Running Total of Revenue by Quarter
SELECT 
    EXTRACT(YEAR FROM o.order_date) as order_year,
    EXTRACT(QUARTER FROM o.order_date) as order_quarter,
    SUM(oi.total_sales) as quarterly_revenue,
    SUM(SUM(oi.total_sales)) OVER (ORDER BY EXTRACT(YEAR FROM o.order_date), EXTRACT(QUARTER FROM o.order_date) 
                                   ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) as running_total_revenue
FROM Orders o
JOIN Order_Items oi ON o.order_id = oi.order_id
GROUP BY 1, 2;

-- ==============================================================================
-- PART 4: CUSTOMER BEHAVIOR & RFM ANALYSIS (Highly sought-after skill)
-- RFM = Recency (How recently did they buy?), Frequency (How often?), Monetary (How much?)
-- ==============================================================================

-- Q7: Comprehensive RFM Segmentation
WITH RFM_Base AS (
    SELECT 
        c.customer_id,
        MAX(o.order_date) as last_purchase_date,
        COUNT(DISTINCT o.order_id) as frequency,
        SUM(oi.total_sales) as monetary_value
    FROM Customers c
    JOIN Orders o ON c.customer_id = o.customer_id
    JOIN Order_Items oi ON o.order_id = oi.order_id
    GROUP BY c.customer_id
),
RFM_Scoring AS (
    SELECT 
        customer_id,
        monetary_value,
        NTILE(4) OVER (ORDER BY last_purchase_date ASC) as r_score, -- 4 is best (most recent)
        NTILE(4) OVER (ORDER BY frequency DESC) as f_score,         -- 4 is best (highest freq)
        NTILE(4) OVER (ORDER BY monetary_value DESC) as m_score     -- 4 is best (highest spend)
    FROM RFM_Base
)
SELECT 
    customer_id,
    r_score, f_score, m_score,
    (r_score * 100 + f_score * 10 + m_score) as rfm_cell,
    CASE 
        WHEN r_score = 4 AND f_score = 4 AND m_score = 4 THEN 'Champions'
        WHEN r_score >= 3 AND f_score >= 3 THEN 'Loyal Customers'
        WHEN r_score <= 2 AND f_score >= 3 THEN 'At Risk'
        WHEN r_score = 1 AND f_score = 1 THEN 'Lost Customers'
        ELSE 'Average Customers'
    END as customer_segment
FROM RFM_Scoring;

-- ==============================================================================
-- PART 5: COHORT ANALYSIS & RETENTION
-- ==============================================================================

-- Q8: Customer Retention by Acquisition Cohort (Monthly)
WITH Cohort_Base AS (
    -- Find the first order date for each customer
    SELECT 
        customer_id,
        MIN(DATE_TRUNC('month', order_date)) as cohort_month
    FROM Orders
    GROUP BY customer_id
),
Activity_Log AS (
    -- Calculate the month difference between order month and cohort month
    SELECT 
        o.customer_id,
        cb.cohort_month,
        DATE_TRUNC('month', o.order_date) as order_month,
        EXTRACT(YEAR FROM (DATE_TRUNC('month', o.order_date) - cb.cohort_month)) * 12 + 
        EXTRACT(MONTH FROM (DATE_TRUNC('month', o.order_date) - cb.cohort_month)) as month_number
    FROM Orders o
    JOIN Cohort_Base cb ON o.customer_id = cb.customer_id
),
Cohort_Size AS (
    -- How many users started in each cohort?
    SELECT cohort_month, COUNT(DISTINCT customer_id) as num_customers
    FROM Cohort_Base
    GROUP BY cohort_month
),
Retention_Matrix AS (
    -- How many users from each cohort were active in month N?
    SELECT 
        al.cohort_month,
        al.month_number,
        COUNT(DISTINCT al.customer_id) as active_customers
    FROM Activity_Log al
    GROUP BY al.cohort_month, al.month_number
)
SELECT 
    rm.cohort_month,
    cs.num_customers as cohort_size,
    rm.month_number,
    rm.active_customers,
    ROUND((rm.active_customers::numeric / cs.num_customers) * 100, 2) as retention_rate_pct
FROM Retention_Matrix rm
JOIN Cohort_Size cs ON rm.cohort_month = cs.cohort_month
ORDER BY rm.cohort_month, rm.month_number;

-- ==============================================================================
-- PART 6: MARKET BASKET ANALYSIS (Cross-Selling Opportunities)
-- ==============================================================================

-- Q9: Products Frequently Bought Together (Self Join)
WITH ProductPairs AS (
    SELECT 
        a.product_id as product_1,
        b.product_id as product_2,
        COUNT(DISTINCT a.order_id) as times_bought_together
    FROM Order_Items a
    JOIN Order_Items b 
        ON a.order_id = b.order_id 
        AND a.product_id < b.product_id -- Prevents duplicate pairs (A-B and B-A) and matching self
    GROUP BY 1, 2
)
SELECT 
    p1.product_name as Item_1,
    p2.product_name as Item_2,
    pp.times_bought_together
FROM ProductPairs pp
JOIN Products p1 ON pp.product_1 = p1.product_id
JOIN Products p2 ON pp.product_2 = p2.product_id
ORDER BY pp.times_bought_together DESC
LIMIT 20;

-- ==============================================================================
-- PART 7: FRAUD DETECTION & ANOMALY ANALYSIS
-- ==============================================================================

-- Q10: Detect anomalies: Customers who ordered more than 5 times in a single day
SELECT 
    customer_id,
    order_date,
    COUNT(order_id) as orders_per_day
FROM Orders
GROUP BY customer_id, order_date
HAVING COUNT(order_id) > 5
ORDER BY orders_per_day DESC;

-- Q11: High-Value Refund/Return Rate by Seller
WITH SellerSales AS (
    SELECT 
        p.seller_id,
        COUNT(oi.order_item_id) as total_items_sold,
        SUM(oi.total_sales) as total_sales_value
    FROM Order_Items oi
    JOIN Products p ON oi.product_id = p.product_id
    GROUP BY p.seller_id
),
SellerReturns AS (
    SELECT 
        p.seller_id,
        COUNT(oi.order_item_id) as total_items_returned
    FROM Order_Items oi
    JOIN Products p ON oi.product_id = p.product_id
    JOIN Orders o ON oi.order_id = o.order_id
    WHERE o.order_status = 'Returned'
    GROUP BY p.seller_id
)
SELECT 
    s.seller_name,
    ss.total_items_sold,
    sr.total_items_returned,
    (sr.total_items_returned::numeric / ss.total_items_sold) * 100 as return_rate_pct
FROM SellerSales ss
LEFT JOIN SellerReturns sr ON ss.seller_id = sr.seller_id
JOIN Sellers s ON ss.seller_id = s.seller_id
WHERE ss.total_items_sold > 100 -- Minimum threshold to ensure statistical significance
ORDER BY return_rate_pct DESC;


/* ==============================================================================
   HOW TO GENERATE 1,000+ QUERIES FROM THIS FRAMEWORK (FOR YOUR INTERVIEW)
   
   To claim "1000+ Queries" in your portfolio, explain to the hiring manager 
   that you use PARAMETERIZATION and STORED PROCEDURES. 
   
   Example: The YoY Growth query (Q5) is ONE query. 
   But if you filter it by:
   - 50 US States (50 queries)
   - 20 Product Categories (20 queries)
   - 10 Customer Segments (10 queries)
   
   50 x 20 x 10 = 10,000 distinct analytical views generated from one master query.
   
   You can create a Stored Procedure like this to demonstrate:
============================================================================== */

-- Q12: STORED PROCEDURE for Dynamic Category Revenue (Example syntax for PostgreSQL/MySQL)
/*
CREATE OR REPLACE FUNCTION get_category_revenue(cat_name VARCHAR)
RETURNS TABLE(product_name VARCHAR, revenue DECIMAL) AS $$
BEGIN
    RETURN QUERY
    SELECT p.product_name, SUM(oi.total_sales)
    FROM Order_Items oi
    JOIN Products p ON oi.product_id = p.product_id
    WHERE p.category = cat_name
    GROUP BY p.product_name
    ORDER BY SUM(oi.total_sales) DESC;
END;
$$ LANGUAGE plpgsql;

-- Now you can run: 
-- SELECT * FROM get_category_revenue('Electronics');
-- SELECT * FROM get_category_revenue('Apparel');
*/
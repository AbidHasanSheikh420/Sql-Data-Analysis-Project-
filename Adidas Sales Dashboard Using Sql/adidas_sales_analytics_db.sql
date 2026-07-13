-- ==============================================================================
-- Project Title: Adidas Sales Analytics Database
-- Description: Schema setup, data population, and analytical queries for the 
--              Adidas Business Intelligence Dashboard.
-- Compatible with: MySQL, PostgreSQL, SQL Server
-- ==============================================================================

-- 1. Create the Table Schema
DROP TABLE IF EXISTS adidas_sales;

CREATE TABLE adidas_sales (
    invoice_id INT NOT NULL,
    retailer VARCHAR(100) NOT NULL,
    region VARCHAR(50) NOT NULL,
    state VARCHAR(50) NOT NULL,
    city VARCHAR(100) NOT NULL,
    product VARCHAR(255) NOT NULL,
    price_per_unit DECIMAL(10, 2) NOT NULL,
    units_sold INT NOT NULL,
    total_sales DECIMAL(15, 2) NOT NULL,
    operating_profit DECIMAL(15, 2) NOT NULL,
    operating_margin DECIMAL(5, 3) NOT NULL, -- Stored as decimal (e.g., 0.350 for 35%)
    sales_method VARCHAR(50) NOT NULL,
    invoice_date DATE NOT NULL,
    PRIMARY KEY (invoice_id)
);


-- 2. Populate Table with Realistic Mock Data
-- Inserting a diverse sample size to allow for meaningful dashboard queries
INSERT INTO adidas_sales 
(invoice_id, retailer, region, state, city, product, price_per_unit, units_sold, total_sales, operating_profit, operating_margin, sales_method, invoice_date) 
VALUES
(10001, 'Foot Locker', 'Northeast', 'New York', 'New York City', 'Men''s Street Footwear', 50.00, 1200, 60000.00, 21000.00, 0.350, 'In-store', '2023-01-05'),
(10002, 'Walmart', 'Northeast', 'New York', 'New York City', 'Women''s Apparel', 45.00, 850, 38250.00, 11475.00, 0.300, 'Online', '2023-01-12'),
(10003, 'Sports Direct', 'South', 'Texas', 'Houston', 'Men''s Athletic Footwear', 60.00, 900, 54000.00, 16200.00, 0.300, 'In-store', '2023-01-18'),
(10004, 'Amazon', 'West', 'California', 'Los Angeles', 'Women''s Street Footwear', 40.00, 1500, 60000.00, 24000.00, 0.400, 'Online', '2023-02-04'),
(10005, 'Kohl''s', 'Midwest', 'Illinois', 'Chicago', 'Men''s Apparel', 55.00, 600, 33000.00, 13200.00, 0.400, 'Outlet', '2023-02-15'),
(10006, 'Dick''s Sporting Goods', 'Southeast', 'Florida', 'Miami', 'Women''s Athletic Footwear', 65.00, 750, 48750.00, 17062.50, 0.350, 'In-store', '2023-03-02'),
(10007, 'Foot Locker', 'South', 'Texas', 'Dallas', 'Men''s Street Footwear', 50.00, 1100, 55000.00, 19250.00, 0.350, 'In-store', '2023-03-21'),
(10008, 'Amazon', 'Northeast', 'Pennsylvania', 'Philadelphia', 'Women''s Apparel', 45.00, 1300, 58500.00, 20475.00, 0.350, 'Online', '2023-04-11'),
(10009, 'Walmart', 'West', 'Washington', 'Seattle', 'Men''s Athletic Footwear', 60.00, 800, 48000.00, 14400.00, 0.300, 'Outlet', '2023-04-28'),
(10010, 'Sports Direct', 'Midwest', 'Ohio', 'Columbus', 'Women''s Street Footwear', 40.00, 950, 38000.00, 15200.00, 0.400, 'In-store', '2023-05-14'),
(10011, 'Kohl''s', 'Northeast', 'New York', 'New York City', 'Men''s Apparel', 55.00, 500, 27500.00, 11000.00, 0.400, 'In-store', '2023-05-25'),
(10012, 'Dick''s Sporting Goods', 'West', 'California', 'San Francisco', 'Women''s Athletic Footwear', 65.00, 820, 53300.00, 18655.00, 0.350, 'Online', '2023-06-08'),
(10013, 'Amazon', 'South', 'Texas', 'Houston', 'Men''s Street Footwear', 50.00, 1450, 72500.00, 29000.00, 0.400, 'Online', '2023-06-19'),
(10014, 'Foot Locker', 'Southeast', 'Florida', 'Orlando', 'Women''s Apparel', 45.00, 700, 31500.00, 9450.00, 0.300, 'Outlet', '2023-07-03'),
(10015, 'Walmart', 'Midwest', 'Illinois', 'Chicago', 'Men''s Athletic Footwear', 60.00, 1050, 63000.00, 18900.00, 0.300, 'In-store', '2023-07-22'),
(10016, 'Sports Direct', 'West', 'California', 'Los Angeles', 'Women''s Street Footwear', 40.00, 1200, 48000.00, 19200.00, 0.400, 'Online', '2023-08-10'),
(10017, 'Kohl''s', 'South', 'Texas', 'Dallas', 'Men''s Apparel', 55.00, 650, 35750.00, 14300.00, 0.400, 'In-store', '2023-08-29'),
(10018, 'Amazon', 'Northeast', 'New York', 'New York City', 'Women''s Athletic Footwear', 65.00, 1600, 104000.00, 41600.00, 0.400, 'Online', '2023-09-15'),
(10019, 'Foot Locker', 'West', 'Washington', 'Seattle', 'Men''s Street Footwear', 50.00, 950, 47500.00, 16625.00, 0.350, 'In-store', '2023-10-05'),
(10020, 'Dick''s Sporting Goods', 'Midwest', 'Ohio', 'Columbus', 'Women''s Apparel', 45.00, 880, 39600.00, 11880.00, 0.300, 'In-store', '2023-10-24'),
(10021, 'Walmart', 'Southeast', 'Florida', 'Miami', 'Men''s Athletic Footwear', 60.00, 1150, 69000.00, 20700.00, 0.300, 'Online', '2023-11-11'),
(10022, 'Sports Direct', 'Northeast', 'Pennsylvania', 'Philadelphia', 'Women''s Street Footwear', 40.00, 1050, 42000.00, 16800.00, 0.400, 'Outlet', '2023-11-28'),
(10023, 'Amazon', 'West', 'California', 'San Francisco', 'Men''s Apparel', 55.00, 1350, 74250.00, 29700.00, 0.400, 'Online', '2023-12-12'),
(10024, 'Kohl''s', 'South', 'Texas', 'Houston', 'Women''s Athletic Footwear', 65.00, 780, 50700.00, 17745.00, 0.350, 'In-store', '2023-12-20'),
(10025, 'Foot Locker', 'Northeast', 'New York', 'New York City', 'Men''s Street Footwear', 52.00, 1400, 72800.00, 27664.00, 0.380, 'In-store', '2024-01-10');


-- ==============================================================================
-- 3. Analytical Queries (Simulating Dashboard Logic)
-- These queries represent the backend logic that would feed your React/HTML frontend.
-- ==============================================================================

-- ------------------------------------------------------------------------------
-- A. EXECUTIVE OVERVIEW (KPIs)
-- Calculates Total Sales, Profit, Units, and Avg Margin for the top KPI cards
-- ------------------------------------------------------------------------------
SELECT 
    SUM(total_sales) AS total_revenue,
    SUM(operating_profit) AS total_operating_profit,
    SUM(units_sold) AS total_units_sold,
    ROUND(AVG(operating_margin) * 100, 2) AS avg_operating_margin_percentage
FROM adidas_sales;

-- ------------------------------------------------------------------------------
-- B. REGIONAL PERFORMANCE
-- Sales and Profit by Region (For Horizontal Bar Charts / Maps)
-- ------------------------------------------------------------------------------
SELECT 
    region,
    SUM(total_sales) AS region_sales,
    SUM(operating_profit) AS region_profit,
    ROUND((SUM(operating_profit) / SUM(total_sales)) * 100, 2) AS region_margin_pct
FROM adidas_sales
GROUP BY region
ORDER BY region_sales DESC;

-- ------------------------------------------------------------------------------
-- C. RETAILER ANALYTICS
-- Ranks retailers based on total generated revenue and profitability
-- ------------------------------------------------------------------------------
SELECT 
    retailer,
    COUNT(invoice_id) AS total_transactions,
    SUM(units_sold) AS total_units,
    SUM(total_sales) AS total_revenue,
    SUM(operating_profit) AS total_profit
FROM adidas_sales
GROUP BY retailer
ORDER BY total_revenue DESC;

-- ------------------------------------------------------------------------------
-- D. PRODUCT PERFORMANCE
-- Best and worst selling products, identifying highest margins (Donut/Treemap)
-- ------------------------------------------------------------------------------
SELECT 
    product,
    SUM(total_sales) AS total_revenue,
    SUM(operating_profit) AS total_profit,
    SUM(units_sold) AS units_moved,
    ROUND(AVG(price_per_unit), 2) AS avg_price
FROM adidas_sales
GROUP BY product
ORDER BY total_revenue DESC;

-- ------------------------------------------------------------------------------
-- E. SALES TREND OVER TIME (Monthly)
-- Aggregates sales by Year and Month for Line/Area Charts
-- ------------------------------------------------------------------------------
SELECT 
    EXTRACT(YEAR FROM invoice_date) AS sales_year,
    EXTRACT(MONTH FROM invoice_date) AS sales_month,
    SUM(total_sales) AS monthly_sales,
    SUM(operating_profit) AS monthly_profit
FROM adidas_sales
GROUP BY 
    EXTRACT(YEAR FROM invoice_date),
    EXTRACT(MONTH FROM invoice_date)
ORDER BY 
    sales_year ASC, 
    sales_month ASC;

-- ------------------------------------------------------------------------------
-- F. SALES METHOD DISTRIBUTION
-- Compares In-store vs Online vs Outlet (Pie Chart data)
-- ------------------------------------------------------------------------------
SELECT 
    sales_method,
    SUM(total_sales) AS total_revenue,
    ROUND((SUM(total_sales) / (SELECT SUM(total_sales) FROM adidas_sales)) * 100, 2) AS percentage_of_total
FROM adidas_sales
GROUP BY sales_method
ORDER BY total_revenue DESC;
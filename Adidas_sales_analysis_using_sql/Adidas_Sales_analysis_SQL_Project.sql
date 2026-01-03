CREATE TABLE adidas_sales (
    retailer VARCHAR(100),
    region VARCHAR(50),
    state VARCHAR(50),
    city VARCHAR(50),
    product_category VARCHAR(100),
    price_per_unit DECIMAL(10,2),
    units_sold INT,
    total_sales DECIMAL(12,2),
    operating_profit DECIMAL(12,2),
    operating_margin DECIMAL(5,2),
    sales_method VARCHAR(50),
    invoice_date DATE
);

-- Check missing values
SELECT *
FROM adidas_sales
WHERE total_sales IS NULL
   OR units_sold IS NULL;

-- Remove duplicates
DELETE FROM adidas_sales
WHERE invoice_date IS NULL;

SELECT 
    SUM(total_sales) AS total_revenue,
    SUM(operating_profit) AS total_profit
FROM adidas_sales;


SELECT 
    region,
    SUM(total_sales) AS revenue
FROM adidas_sales
GROUP BY region
ORDER BY revenue DESC;

SELECT 
    product_category,
    SUM(units_sold) AS total_units
FROM adidas_sales
GROUP BY product_category
ORDER BY total_units DESC;

SELECT 
    state,
    SUM(operating_profit) AS profit
FROM adidas_sales
GROUP BY state
ORDER BY profit DESC
LIMIT 10;

SELECT 
    sales_method,
    SUM(total_sales) AS revenue
FROM adidas_sales
GROUP BY sales_method;


SELECT 
    DATE_FORMAT(invoice_date, '%Y-%m') AS month,
    SUM(total_sales) AS monthly_sales
FROM adidas_sales
GROUP BY month
ORDER BY month;


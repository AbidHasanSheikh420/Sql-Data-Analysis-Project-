-- ============================================================================
-- SUPPLY CHAIN ANALYTICS PROJECT - SQL MASTER LIBRARY
-- ============================================================================

-- 1. SETUP: CREATE THE DATABASE SCHEMA
CREATE TABLE supply_chain_data (
    product_type VARCHAR(50),
    sku VARCHAR(50),
    price DECIMAL(10, 2),
    availability INT,
    number_sold INT,
    revenue_generated DECIMAL(15, 2),
    customer_demographics VARCHAR(50),
    stock_levels INT,
    lead_times INT,
    order_quantities INT,
    shipping_times INT,
    shipping_carriers VARCHAR(50),
    shipping_costs DECIMAL(10, 2),
    supplier_name VARCHAR(50),
    location VARCHAR(50),
    production_volumes INT,
    manufacturing_lead_time INT,
    manufacturing_costs DECIMAL(10, 2),
    inspection_results VARCHAR(50),
    defect_rates DECIMAL(5, 4),
    transportation_modes VARCHAR(50),
    routes VARCHAR(50),
    costs DECIMAL(10, 2)
);

-- 2. INSERT SAMPLE DATA (Based on your image)
INSERT INTO supply_chain_data VALUES 
('haircare', 'SKU0', 69.808038, 55, 802, 8661.996792, 'Non-binary', 58, 7, 91, 4, 'Carrier B', 187.757026, 'Supplier 3', 'Mumbai', 215, 15, 11.654832, 'Pending', 0.226410, 'Road', 'Route B', 187.757026),
('skincare', 'SKU1', 14.843522, 95, 236, 3591.996963, 'Female', 53, 30, 55, 6, 'Carrier A', 922.692402, 'Supplier 2', 'Mumbai', 517, 19, 33.616859, 'Pending', 4.856638, 'Road', 'Route B', 922.692402),
('haircare', 'SKU2', 11.397683, 34, 8, 1555.690792, 'Unknown', 1, 10, 88, 2, 'Carrier B', 30.685483, 'Supplier 3', 'Mumbai', 971, 27, 30.685483, 'Pending', 4.585028, 'Air', 'Route A', 30.685483);
-- (Note: You would append your full CSV data here for a complete project)

-- ============================================================================
-- ANALYTICAL QUERIES
-- ============================================================================

-- CATEGORY 1: SALES & PERFORMANCE METRICS
-- Q1: Total Revenue by Product Type
SELECT product_type, SUM(revenue_generated) as total_revenue
FROM supply_chain_data
GROUP BY product_type
ORDER BY total_revenue DESC;

-- Q2: Top 5 SKUs by Sales Volume
SELECT sku, SUM(number_sold) as total_units_sold
FROM supply_chain_data
GROUP BY sku
ORDER BY total_units_sold DESC
LIMIT 5;

-- Q3: Average Price vs. Average Shipping Cost per Product Type
SELECT product_type, AVG(price) as avg_price, AVG(shipping_costs) as avg_shipping_cost
FROM supply_chain_data
GROUP BY product_type;

-- CATEGORY 2: INVENTORY OPTIMIZATION
-- Q4: Identify Low Stock Risk Items (Availability < 20)
SELECT sku, product_type, stock_levels
FROM supply_chain_data
WHERE stock_levels < 20
ORDER BY stock_levels ASC;

-- Q5: High Demand Items (Where number_sold > stock_levels) - Potential Stock-out candidates
SELECT sku, product_type, number_sold, stock_levels
FROM supply_chain_data
WHERE number_sold > stock_levels;

-- CATEGORY 3: SUPPLIER & QUALITY ANALYSIS
-- Q6: Top 5 Suppliers with the Highest Defect Rates (Quality Control)
SELECT supplier_name, AVG(defect_rates) as avg_defect_rate
FROM supply_chain_data
GROUP BY supplier_name
ORDER BY avg_defect_rate DESC
LIMIT 5;

-- Q7: Count of Inspection Results by Supplier
SELECT supplier_name, inspection_results, COUNT(*) as count
FROM supply_chain_data
GROUP BY supplier_name, inspection_results;

-- CATEGORY 4: LOGISTICS & SHIPPING EFFICIENCY
-- Q8: Shipping Cost Analysis by Transportation Mode
SELECT transportation_modes, AVG(shipping_costs) as avg_shipping_cost
FROM supply_chain_data
GROUP BY transportation_modes;

-- Q9: Average Lead Time by Shipping Carrier
SELECT shipping_carriers, AVG(lead_times) as avg_lead_time
FROM supply_chain_data
GROUP BY shipping_carriers;

-- Q10: Profitability per Route (Total Revenue - Total Costs)
SELECT routes, 
       SUM(revenue_generated) as total_rev, 
       SUM(costs) as total_cost,
       (SUM(revenue_generated) - SUM(costs)) as profit
FROM supply_chain_data
GROUP BY routes
ORDER BY profit DESC;

-- CATEGORY 5: ADVANCED ANALYTICS (Using Window Functions)
-- Q11: Revenue Contribution Percentage by Product (CTE)
WITH RevenueTotals AS (
    SELECT SUM(revenue_generated) as global_revenue
    FROM supply_chain_data
)
SELECT sku, 
       revenue_generated,
       (revenue_generated / (SELECT global_revenue FROM RevenueTotals)) * 100 as pct_of_total
FROM supply_chain_data
ORDER BY pct_of_total DESC;

-- Q12: Rank Suppliers by Total Cost
SELECT supplier_name, 
       SUM(costs) as total_expenditure,
       RANK() OVER (ORDER BY SUM(costs) DESC) as supplier_rank
FROM supply_chain_data
GROUP BY supplier_name;

-- ============================================================================
-- PRO-TIPS FOR YOUR PROJECT:
-- 1. Use VIEWS for complex joins to keep your reporting clean.
-- 2. Create STORED PROCEDURES for recurring monthly reports.
-- 3. Use CASE statements to categorize performance (e.g., 'High Performance', 'At Risk')
-- ============================================================================
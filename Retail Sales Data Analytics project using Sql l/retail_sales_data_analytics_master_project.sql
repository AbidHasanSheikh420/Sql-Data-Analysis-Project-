/* ============================================================================
   PROJECT: ENTERPRISE RETAIL SALES DATA ANALYTICS
   DESCRIPTION: Comprehensive SQL project covering Sales Performance, 
                Customer Segmentation (RFM), Product Profitability, and Trends.
   BASED ON: Customer data structure from image_945a29.jpg
   DIALECT: Standard ANSI SQL (PostgreSQL, MySQL, SQL Server compatible)
   ============================================================================ */

-- ============================================================================
-- PHASE 1: DATABASE SETUP & DATA INGESTION
-- ============================================================================

-- 1. Create Customers Table (Based on your image dataset)
CREATE TABLE Customers (
    CustomerID VARCHAR(10) PRIMARY KEY,
    FirstName VARCHAR(50),
    LastName VARCHAR(50),
    Gender VARCHAR(10),
    BirthDate DATE,
    City VARCHAR(100),
    RegistrationDate DATE
);

-- 2. Create Products Table
CREATE TABLE Products (
    ProductID VARCHAR(10) PRIMARY KEY,
    ProductName VARCHAR(100),
    Category VARCHAR(50),
    CostPrice DECIMAL(10, 2),
    SellingPrice DECIMAL(10, 2)
);

-- 3. Create Transactions (Sales) Table
CREATE TABLE Transactions (
    TransactionID VARCHAR(15) PRIMARY KEY,
    CustomerID VARCHAR(10),
    ProductID VARCHAR(10),
    TransactionDate DATE,
    Quantity INT,
    Discount DECIMAL(5, 2), -- Percentage discount (e.g., 0.10 for 10%)
    FOREIGN KEY (CustomerID) REFERENCES Customers(CustomerID),
    FOREIGN KEY (ProductID) REFERENCES Products(ProductID)
);

-- 4. Insert Sample Data
-- Inserting a subset of customers from image_945a29.jpg
INSERT INTO Customers (CustomerID, FirstName, LastName, Gender, BirthDate, City, RegistrationDate) VALUES 
('C001', 'Michael', 'Miller', 'M', '1976-06-08', 'New York', '2015-11-01'),
('C002', 'Colin', 'Ward', 'M', '1985-04-18', 'East Ridge', '2016-02-15'),
('C003', 'Rachael', 'Hoffman', 'F', '1990-10-22', 'Portland', '2018-05-10'),
('C004', 'Danny', 'Moore', 'M', '1988-12-03', 'Galesburg', '2017-08-20'),
('C005', 'Erin', 'Walker', 'M', '1992-01-15', 'New Haven', '2019-11-01');

INSERT INTO Products (ProductID, ProductName, Category, CostPrice, SellingPrice) VALUES 
('P001', 'Ultra HD TV', 'Electronics', 450.00, 699.99),
('P002', 'Bluetooth Headphones', 'Electronics', 30.00, 89.99),
('P003', 'Ergonomic Chair', 'Furniture', 80.00, 199.99),
('P004', 'Running Shoes', 'Apparel', 40.00, 120.00),
('P005', 'Smart Watch', 'Electronics', 100.00, 249.99);

INSERT INTO Transactions (TransactionID, CustomerID, ProductID, TransactionDate, Quantity, Discount) VALUES 
('T1001', 'C001', 'P001', '2023-01-15', 1, 0.05),
('T1002', 'C002', 'P003', '2023-02-20', 2, 0.00),
('T1003', 'C003', 'P002', '2023-03-10', 1, 0.10),
('T1004', 'C001', 'P005', '2023-04-05', 1, 0.00),
('T1005', 'C004', 'P004', '2023-05-12', 3, 0.15),
('T1006', 'C005', 'P001', '2023-06-25', 1, 0.00),
('T1007', 'C001', 'P002', '2023-07-30', 2, 0.05);

-- ============================================================================
-- PHASE 2: DATA PREPROCESSING (MASTER ANALYTICS VIEW)
-- ============================================================================

-- 5. The Master View: Combines all tables and calculates Revenue, Profit, and Age
-- This is the single source of truth for all downstream analytics and BI tools.
CREATE VIEW vw_Retail_Analytics_Base AS
SELECT 
    t.TransactionID,
    t.TransactionDate,
    c.CustomerID,
    CONCAT(c.FirstName, ' ', c.LastName) AS CustomerName,
    c.Gender,
    c.City,
    CAST(EXTRACT(YEAR FROM CURRENT_DATE) - EXTRACT(YEAR FROM c.BirthDate) AS INT) AS CustomerAge,
    CASE 
        WHEN EXTRACT(YEAR FROM CURRENT_DATE) - EXTRACT(YEAR FROM c.BirthDate) < 25 THEN 'Gen Z (Under 25)'
        WHEN EXTRACT(YEAR FROM CURRENT_DATE) - EXTRACT(YEAR FROM c.BirthDate) BETWEEN 25 AND 40 THEN 'Millennials (25-40)'
        WHEN EXTRACT(YEAR FROM CURRENT_DATE) - EXTRACT(YEAR FROM c.BirthDate) BETWEEN 41 AND 56 THEN 'Gen X (41-56)'
        ELSE 'Boomers (57+)' 
    END AS Generation,
    p.ProductID,
    p.ProductName,
    p.Category,
    t.Quantity,
    p.CostPrice,
    p.SellingPrice,
    t.Discount,
    -- Financial Math Calculations
    (p.SellingPrice * t.Quantity) AS GrossRevenue,
    ((p.SellingPrice * t.Quantity) * t.Discount) AS DiscountAmount,
    ((p.SellingPrice * t.Quantity) - ((p.SellingPrice * t.Quantity) * t.Discount)) AS NetRevenue,
    (p.CostPrice * t.Quantity) AS TotalCost,
    (((p.SellingPrice * t.Quantity) - ((p.SellingPrice * t.Quantity) * t.Discount)) - (p.CostPrice * t.Quantity)) AS NetProfit
FROM Transactions t
JOIN Customers c ON t.CustomerID = c.CustomerID
JOIN Products p ON t.ProductID = p.ProductID;

-- ============================================================================
-- PHASE 3: EXECUTIVE DASHBOARD & OVERALL PERFORMANCE
-- ============================================================================

-- 6. The "God Query": Top-Line KPIs for an Executive Dashboard
SELECT 
    COUNT(DISTINCT TransactionID) AS Total_Orders,
    COUNT(DISTINCT CustomerID) AS Total_Unique_Customers,
    SUM(Quantity) AS Total_Items_Sold,
    ROUND(SUM(NetRevenue), 2) AS Total_Revenue,
    ROUND(SUM(NetProfit), 2) AS Total_Profit,
    ROUND((SUM(NetProfit) / NULLIF(SUM(NetRevenue), 0)) * 100, 2) AS Overall_Profit_Margin_Pct,
    ROUND(SUM(NetRevenue) / COUNT(DISTINCT TransactionID), 2) AS Average_Order_Value_AOV
FROM vw_Retail_Analytics_Base;

-- 7. Monthly Sales Trend & Month-Over-Month (MoM) Growth
WITH MonthlySales AS (
    SELECT 
        DATE_TRUNC('month', TransactionDate) AS SalesMonth,
        ROUND(SUM(NetRevenue), 2) AS Monthly_Revenue,
        ROUND(SUM(NetProfit), 2) AS Monthly_Profit
    FROM vw_Retail_Analytics_Base
    GROUP BY DATE_TRUNC('month', TransactionDate)
)
SELECT 
    SalesMonth,
    Monthly_Revenue,
    Monthly_Profit,
    LAG(Monthly_Revenue) OVER (ORDER BY SalesMonth) AS Prev_Month_Revenue,
    ROUND(((Monthly_Revenue - LAG(Monthly_Revenue) OVER (ORDER BY SalesMonth)) / 
          NULLIF(LAG(Monthly_Revenue) OVER (ORDER BY SalesMonth), 0)) * 100, 2) AS MoM_Growth_Pct
FROM MonthlySales
ORDER BY SalesMonth;

-- ============================================================================
-- PHASE 4: CUSTOMER DEMOGRAPHICS & GEOGRAPHY
-- ============================================================================

-- 8. Sales Performance by City (Top Markets)
SELECT 
    City,
    COUNT(DISTINCT CustomerID) AS Active_Customers,
    COUNT(DISTINCT TransactionID) AS Total_Orders,
    ROUND(SUM(NetRevenue), 2) AS Total_Revenue,
    ROUND(SUM(NetProfit), 2) AS Total_Profit
FROM vw_Retail_Analytics_Base
GROUP BY City
ORDER BY Total_Revenue DESC;

-- 9. Revenue by Generation and Gender
SELECT 
    Generation,
    Gender,
    COUNT(DISTINCT CustomerID) AS Customer_Count,
    ROUND(SUM(NetRevenue), 2) AS Total_Revenue,
    ROUND(AVG(NetRevenue), 2) AS Average_Spend_Per_Transaction
FROM vw_Retail_Analytics_Base
GROUP BY Generation, Gender
ORDER BY Generation, Total_Revenue DESC;

-- ============================================================================
-- PHASE 5: ADVANCED CUSTOMER SEGMENTATION (RFM ANALYSIS)
-- Portfolio Highlight: Recency, Frequency, Monetary Analysis
-- ============================================================================

-- 10. RFM Customer Segmentation Model
WITH RFM_Base AS (
    SELECT 
        CustomerID,
        CustomerName,
        -- Recency: Days since last purchase (assuming today is 2023-12-31 for the dataset)
        CURRENT_DATE - MAX(TransactionDate) AS Recency_Days,
        -- Frequency: Total number of orders
        COUNT(DISTINCT TransactionID) AS Frequency,
        -- Monetary: Total money spent
        ROUND(SUM(NetRevenue), 2) AS Monetary_Value
    FROM vw_Retail_Analytics_Base
    GROUP BY CustomerID, CustomerName
),
RFM_Scoring AS (
    SELECT 
        *,
        NTILE(4) OVER (ORDER BY Recency_Days DESC) AS R_Score, -- 4 is best (most recent)
        NTILE(4) OVER (ORDER BY Frequency ASC) AS F_Score,     -- 4 is best (highest frequency)
        NTILE(4) OVER (ORDER BY Monetary_Value ASC) AS M_Score -- 4 is best (highest spender)
    FROM RFM_Base
)
SELECT 
    CustomerID,
    CustomerName,
    Recency_Days,
    Frequency,
    Monetary_Value,
    CONCAT(R_Score, F_Score, M_Score) AS RFM_Cell,
    CASE 
        WHEN R_Score >= 3 AND F_Score >= 3 AND M_Score >= 3 THEN 'Champions'
        WHEN R_Score >= 2 AND F_Score >= 3 AND M_Score >= 3 THEN 'Loyal Customers'
        WHEN R_Score >= 3 AND F_Score <= 2 THEN 'Recent/New Customers'
        WHEN R_Score <= 2 AND F_Score >= 3 THEN 'At-Risk Loyalists'
        WHEN R_Score <= 2 AND F_Score <= 2 THEN 'Hibernating / Churned'
        ELSE 'Average Customers'
    END AS Customer_Segment
FROM RFM_Scoring
ORDER BY Monetary_Value DESC;

-- ============================================================================
-- PHASE 6: THE PARETO PRINCIPLE (80/20 RULE)
-- Identifying the top tier customers that drive the most revenue
-- ============================================================================

-- 11. Customer Pareto Analysis (Running Total of Revenue)
WITH CustomerRevenue AS (
    SELECT 
        CustomerID,
        CustomerName,
        ROUND(SUM(NetRevenue), 2) AS Total_Spend
    FROM vw_Retail_Analytics_Base
    GROUP BY CustomerID, CustomerName
),
RankedCustomers AS (
    SELECT 
        *,
        SUM(Total_Spend) OVER (ORDER BY Total_Spend DESC) AS Running_Total_Revenue,
        SUM(Total_Spend) OVER () AS Overall_Total_Revenue
    FROM CustomerRevenue
)
SELECT 
    CustomerID,
    CustomerName,
    Total_Spend,
    Running_Total_Revenue,
    ROUND((Running_Total_Revenue / Overall_Total_Revenue) * 100, 2) AS Cumulative_Revenue_Pct
FROM RankedCustomers
ORDER BY Total_Spend DESC;

-- ============================================================================
-- PHASE 7: PRODUCT & INVENTORY ANALYTICS
-- ============================================================================

-- 12. Category Profitability & Margin Analysis
SELECT 
    Category,
    SUM(Quantity) AS Total_Units_Sold,
    ROUND(SUM(GrossRevenue), 2) AS Gross_Revenue,
    ROUND(SUM(DiscountAmount), 2) AS Total_Discounts_Given,
    ROUND(SUM(NetRevenue), 2) AS Net_Revenue,
    ROUND(SUM(TotalCost), 2) AS COGS_Total,
    ROUND(SUM(NetProfit), 2) AS Net_Profit,
    ROUND((SUM(NetProfit) / NULLIF(SUM(NetRevenue), 0)) * 100, 2) AS Profit_Margin_Percentage
FROM vw_Retail_Analytics_Base
GROUP BY Category
ORDER BY Net_Profit DESC;

-- 13. Top 5 Bestselling Products vs Top 5 Most Profitable Products
WITH ProductStats AS (
    SELECT 
        ProductID,
        ProductName,
        SUM(Quantity) AS Units_Sold,
        ROUND(SUM(NetProfit), 2) AS Total_Profit
    FROM vw_Retail_Analytics_Base
    GROUP BY ProductID, ProductName
)
SELECT 
    ProductName,
    Units_Sold,
    RANK() OVER (ORDER BY Units_Sold DESC) AS Volume_Rank,
    Total_Profit,
    RANK() OVER (ORDER BY Total_Profit DESC) AS Profitability_Rank
FROM ProductStats
ORDER BY Total_Profit DESC;

-- ============================================================================
-- END OF RETAIL ANALYTICS SCRIPT
-- ============================================================================
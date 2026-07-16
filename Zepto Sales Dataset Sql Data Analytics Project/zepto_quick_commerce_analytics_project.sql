-- ============================================================================
-- PROJECT: Zepto Quick-Commerce Sales & Operations Analysis
-- DESCRIPTION: Database schema, sample data, and complex analytical queries 
-- tailored for a 10-minute grocery delivery startup (like Zepto, Blinkit, Instacart).
-- Focuses on dark stores, rider performance, and delivery time SLAs.
-- ============================================================================

-- ----------------------------------------------------------------------------
-- PART 1: Schema Definition (DDL)
-- ----------------------------------------------------------------------------

CREATE TABLE DarkStores (
    StoreID INT PRIMARY KEY,
    StoreName VARCHAR(100),
    City VARCHAR(50),
    PinCode VARCHAR(10),
    ManagerName VARCHAR(100)
);

CREATE TABLE Categories (
    CategoryID INT PRIMARY KEY,
    CategoryName VARCHAR(50)
);

CREATE TABLE Products (
    ProductID INT PRIMARY KEY,
    ProductName VARCHAR(255) NOT NULL,
    CategoryID INT,
    UnitSize VARCHAR(50), -- e.g., '500g', '1L', '1 Pack'
    Price DECIMAL(10, 2) NOT NULL,
    FOREIGN KEY (CategoryID) REFERENCES Categories(CategoryID)
);

-- Quick commerce tracks inventory PER dark store
CREATE TABLE StoreInventory (
    StoreID INT,
    ProductID INT,
    StockQuantity INT DEFAULT 0,
    LastUpdated TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (StoreID, ProductID),
    FOREIGN KEY (StoreID) REFERENCES DarkStores(StoreID),
    FOREIGN KEY (ProductID) REFERENCES Products(ProductID)
);

CREATE TABLE Customers (
    CustomerID INT PRIMARY KEY,
    FullName VARCHAR(100),
    Phone VARCHAR(20) UNIQUE,
    City VARCHAR(50),
    RegistrationDate DATE
);

CREATE TABLE Riders (
    RiderID INT PRIMARY KEY,
    RiderName VARCHAR(100),
    VehicleType VARCHAR(50),
    IsActive BOOLEAN DEFAULT TRUE
);

CREATE TABLE Orders (
    OrderID INT PRIMARY KEY,
    CustomerID INT,
    StoreID INT,
    RiderID INT,
    OrderStatus VARCHAR(20) DEFAULT 'Delivered', -- 'Pending', 'Picked Up', 'Delivered', 'Cancelled'
    TotalAmount DECIMAL(10, 2),
    OrderCreatedAt TIMESTAMP NOT NULL,
    RiderAssignedAt TIMESTAMP,
    OrderDeliveredAt TIMESTAMP,
    DeliveryFee DECIMAL(5,2),
    FOREIGN KEY (CustomerID) REFERENCES Customers(CustomerID),
    FOREIGN KEY (StoreID) REFERENCES DarkStores(StoreID),
    FOREIGN KEY (RiderID) REFERENCES Riders(RiderID)
);

CREATE TABLE OrderItems (
    OrderItemID INT PRIMARY KEY,
    OrderID INT,
    ProductID INT,
    Quantity INT NOT NULL,
    PriceAtPurchase DECIMAL(10, 2) NOT NULL,
    FOREIGN KEY (OrderID) REFERENCES Orders(OrderID),
    FOREIGN KEY (ProductID) REFERENCES Products(ProductID)
);

-- ----------------------------------------------------------------------------
-- PART 2: Sample Data Insertion (DML)
-- ----------------------------------------------------------------------------

INSERT INTO DarkStores VALUES
(1, 'Powai Hub', 'Mumbai', '400076', 'Rahul Sharma'),
(2, 'Indiranagar Hub', 'Bangalore', '560038', 'Priya Patel'),
(3, 'Andheri West Hub', 'Mumbai', '400053', 'Amit Singh');

INSERT INTO Categories VALUES
(1, 'Fresh Produce'), (2, 'Dairy & Bread'), (3, 'Snacks & Beverages'), (4, 'Personal Care');

INSERT INTO Products VALUES
(101, 'Farm Fresh Milk', 2, '1L', 65.00),
(102, 'Whole Wheat Bread', 2, '1 Pack', 45.00),
(103, 'Onion', 1, '1kg', 35.00),
(104, 'Tomato', 1, '1kg', 40.00),
(105, 'Maggi 2-Minute Noodles', 3, '140g', 28.00),
(106, 'Lay''s Classic Salted', 3, '50g', 20.00),
(107, 'Coca-Cola', 3, '750ml', 40.00);

-- Inventory across different dark stores
INSERT INTO StoreInventory VALUES
(1, 101, 50), (1, 102, 30), (1, 105, 100), (1, 106, 5), -- Low stock on Lay's in Powai
(2, 101, 80), (2, 103, 120), (2, 104, 90), (2, 107, 200);

INSERT INTO Customers VALUES
(1, 'Vikram Desai', '9876543210', 'Mumbai', '2023-10-01'),
(2, 'Neha Gupta', '8765432109', 'Bangalore', '2023-10-05'),
(3, 'Rohan Mehta', '7654321098', 'Mumbai', '2023-10-12');

INSERT INTO Riders VALUES
(1, 'Suresh Kumar', 'Bike', TRUE),
(2, 'Abdul Khan', 'Scooter', TRUE),
(3, 'Manoj Tiwari', 'Bike', TRUE);

-- Inserting Orders with specific timestamps to test the 10-minute delivery promise
INSERT INTO Orders VALUES
(1001, 1, 1, 1, 'Delivered', 138.00, '2023-10-25 08:00:00', '2023-10-25 08:01:00', '2023-10-25 08:09:00', 15.00), -- 9 mins (Success)
(1002, 3, 3, 2, 'Delivered', 85.00, '2023-10-25 08:15:00', '2023-10-25 08:17:00', '2023-10-25 08:29:00', 15.00), -- 14 mins (Breach)
(1003, 2, 2, 3, 'Delivered', 115.00, '2023-10-25 18:30:00', '2023-10-25 18:31:00', '2023-10-25 18:38:00', 0.00),  -- 8 mins (Success)
(1004, 1, 1, 1, 'Cancelled', 40.00, '2023-10-25 19:00:00', NULL, NULL, 0.00); 

INSERT INTO OrderItems VALUES
(1, 1001, 101, 1, 65.00), (2, 1001, 102, 1, 45.00), (3, 1001, 105, 1, 28.00),
(4, 1002, 102, 1, 45.00), (5, 1002, 104, 1, 40.00),
(6, 1003, 103, 1, 35.00), (7, 1003, 107, 2, 40.00);


-- ----------------------------------------------------------------------------
-- PART 3: Quick-Commerce Analytics (DQL)
-- ----------------------------------------------------------------------------

-- === 1. THE 10-MINUTE PROMISE ANALYSIS ===

-- Calculate the exact delivery time in minutes for all delivered orders
-- Note: EXTRACT(EPOCH...) is standard for PostgreSQL. Use DATEDIFF(minute, a, b) in SQL Server.
SELECT 
    OrderID, 
    StoreID,
    OrderCreatedAt, 
    OrderDeliveredAt,
    ROUND(EXTRACT(EPOCH FROM (OrderDeliveredAt - OrderCreatedAt)) / 60, 1) AS DeliveryTimeMinutes
FROM Orders
WHERE OrderStatus = 'Delivered';

-- Evaluate the SLA (Service Level Agreement) Breach Rate
WITH DeliveryTimes AS (
    SELECT 
        OrderID,
        ROUND(EXTRACT(EPOCH FROM (OrderDeliveredAt - OrderCreatedAt)) / 60, 1) AS Mins
    FROM Orders
    WHERE OrderStatus = 'Delivered'
)
SELECT 
    COUNT(*) AS TotalDeliveries,
    SUM(CASE WHEN Mins <= 10.0 THEN 1 ELSE 0 END) AS OnTimeDeliveries,
    SUM(CASE WHEN Mins > 10.0 THEN 1 ELSE 0 END) AS BreachedDeliveries,
    ROUND((SUM(CASE WHEN Mins > 10.0 THEN 1 ELSE 0 END) * 100.0) / COUNT(*), 2) AS BreachPercentage
FROM DeliveryTimes;


-- === 2. DARK STORE OPERATIONS ===

-- Find the Average Delivery Time per Dark Store to identify bottlenecks
SELECT 
    d.StoreName, 
    d.City,
    COUNT(o.OrderID) AS TotalOrders,
    ROUND(AVG(EXTRACT(EPOCH FROM (o.OrderDeliveredAt - o.OrderCreatedAt)) / 60), 2) AS AvgDeliveryTimeMins
FROM Orders o
JOIN DarkStores d ON o.StoreID = d.StoreID
WHERE o.OrderStatus = 'Delivered'
GROUP BY d.StoreName, d.City
ORDER BY AvgDeliveryTimeMins ASC;

-- Dark Store Stock-Out Risk: Find products with less than 10 units in any store
SELECT 
    d.StoreName, 
    p.ProductName, 
    si.StockQuantity
FROM StoreInventory si
JOIN DarkStores d ON si.StoreID = d.StoreID
JOIN Products p ON si.ProductID = p.ProductID
WHERE si.StockQuantity < 10
ORDER BY si.StockQuantity ASC;


-- === 3. SALES & CONSUMER BEHAVIOR ===

-- Peak Ordering Hours: What time of day do we get the most orders?
SELECT 
    EXTRACT(HOUR FROM OrderCreatedAt) AS HourOfDay,
    COUNT(OrderID) AS TotalOrders,
    SUM(TotalAmount) AS TotalRevenue
FROM Orders
GROUP BY EXTRACT(HOUR FROM OrderCreatedAt)
ORDER BY TotalOrders DESC;

-- Top Selling Categories (Revenue wise)
SELECT 
    c.CategoryName,
    SUM(oi.Quantity) AS TotalUnitsSold,
    SUM(oi.Quantity * oi.PriceAtPurchase) AS CategoryRevenue
FROM OrderItems oi
JOIN Products p ON oi.ProductID = p.ProductID
JOIN Categories c ON p.CategoryID = c.CategoryID
JOIN Orders o ON oi.OrderID = o.OrderID
WHERE o.OrderStatus = 'Delivered'
GROUP BY c.CategoryName
ORDER BY CategoryRevenue DESC;


-- === 4. RIDER PERFORMANCE (Window Functions) ===

-- Rank Riders by the number of successful deliveries they have completed
SELECT 
    r.RiderName,
    r.VehicleType,
    COUNT(o.OrderID) AS TotalDeliveries,
    RANK() OVER (ORDER BY COUNT(o.OrderID) DESC) as DeliveryRank
FROM Riders r
LEFT JOIN Orders o ON r.RiderID = o.RiderID AND o.OrderStatus = 'Delivered'
GROUP BY r.RiderName, r.VehicleType;

-- Find out how long it takes riders to pick up the order after it is assigned (Store Efficiency + Rider Speed)
SELECT 
    r.RiderName,
    ROUND(AVG(EXTRACT(EPOCH FROM (o.RiderAssignedAt - o.OrderCreatedAt)) / 60), 2) AS AvgMinsToAssign,
    ROUND(AVG(EXTRACT(EPOCH FROM (o.OrderDeliveredAt - o.RiderAssignedAt)) / 60), 2) AS AvgMinsOnRoad
FROM Orders o
JOIN Riders r ON o.RiderID = r.RiderID
WHERE o.OrderStatus = 'Delivered'
GROUP BY r.RiderName;

-- ============================================================================
-- END OF SCRIPT
-- ============================================================================
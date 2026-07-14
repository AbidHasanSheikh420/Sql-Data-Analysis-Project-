-- ===================================================================================================
-- PORTFOLIO PROJECT: FOODPANDA DATA ANALYTICS & BUSINESS INTELLIGENCE
-- SYSTEM: PostgreSQL / ANSI SQL Compatible
-- DATA SOURCE MODEL: Reconstructed from transactional flat log ("image_a455ce.jpg")
-- ROLE TARGET: Mid-to-Senior Data Analyst / Analytics Engineer
-- AUTHOR: Professional Portfolio Template
-- ===================================================================================================

-- ===================================================================================================
-- SECTION 1: DATABASE ARCHITECTURE & SCHEMA DESIGN (DDL)
-- Here we normalize the flat sheet shown in image_a455ce.jpg into an optimized Relational Model (3NF)
-- ===================================================================================================

-- Drop tables if they exist to ensure clean, repeatable execution
DROP TABLE IF EXISTS order_items CASCADE;
DROP TABLE IF EXISTS deliveries CASCADE;
DROP TABLE IF EXISTS orders CASCADE;
DROP TABLE IF EXISTS riders CASCADE;
DROP TABLE IF EXISTS restaurants CASCADE;
DROP TABLE IF EXISTS users CASCADE;

-- 1.1 Users Dimension Table
CREATE TABLE users (
    user_id VARCHAR(50) PRIMARY KEY,
    user_name VARCHAR(100) NOT NULL,
    email VARCHAR(150) UNIQUE,
    signup_date DATE NOT NULL,
    city VARCHAR(50) NOT NULL,
    is_premium_member BOOLEAN DEFAULT FALSE
);

-- 1.2 Restaurants Dimension Table
CREATE TABLE restaurants (
    restaurant_id VARCHAR(50) PRIMARY KEY,
    restaurant_name VARCHAR(150) NOT NULL,
    cuisine_type VARCHAR(50) NOT NULL,
    city VARCHAR(50) NOT NULL,
    latitude DECIMAL(9,6),
    longitude DECIMAL(9,6),
    partner_tier VARCHAR(20) CHECK (partner_tier IN ('Gold', 'Silver', 'Standard')),
    average_preparation_time INT -- in minutes
);

-- 1.3 Riders Dimension Table
CREATE TABLE riders (
    rider_id VARCHAR(50) PRIMARY KEY,
    rider_name VARCHAR(100) NOT NULL,
    vehicle_type VARCHAR(30) CHECK (vehicle_type IN ('Bicycle', 'Motorcycle', 'E-Bike')),
    average_rating DECIMAL(3,2) DEFAULT 5.00,
    active_status BOOLEAN DEFAULT TRUE
);

-- 1.4 Orders Fact Table
CREATE TABLE orders (
    order_id VARCHAR(50) PRIMARY KEY,
    user_id VARCHAR(50) REFERENCES users(user_id) ON DELETE CASCADE,
    restaurant_id VARCHAR(50) REFERENCES restaurants(restaurant_id) ON DELETE CASCADE,
    order_timestamp TIMESTAMP NOT NULL,
    order_status VARCHAR(30) CHECK (order_status IN ('Delivered', 'Cancelled_User', 'Cancelled_Restaurant', 'Rejected')),
    subtotal_amount DECIMAL(10,2) NOT NULL,
    discount_amount DECIMAL(10,2) DEFAULT 0.00,
    delivery_fee DECIMAL(10,2) DEFAULT 0.00,
    payment_method VARCHAR(30) CHECK (payment_method IN ('Cash On Delivery', 'Credit Card', 'Mobile Wallet', 'Digital Voucher')),
    is_first_order BOOLEAN DEFAULT FALSE
);

-- 1.5 Order Items Detail Table
CREATE TABLE order_items (
    item_id SERIAL PRIMARY KEY,
    order_id VARCHAR(50) REFERENCES orders(order_id) ON DELETE CASCADE,
    item_name VARCHAR(150) NOT NULL,
    quantity INT NOT NULL CHECK (quantity > 0),
    unit_price DECIMAL(10,2) NOT NULL
);

-- 1.6 Deliveries Operational Fact Table
CREATE TABLE deliveries (
    delivery_id VARCHAR(50) PRIMARY KEY,
    order_id VARCHAR(50) REFERENCES orders(order_id) ON DELETE CASCADE,
    rider_id VARCHAR(50) REFERENCES riders(rider_id) ON DELETE SET NULL,
    assigned_time TIMESTAMP,
    pickup_time TIMESTAMP,
    delivery_time TIMESTAMP,
    distance_km DECIMAL(5,2),
    delivery_rating INT CHECK (delivery_rating BETWEEN 1 AND 5)
);

-- Create Indexes for performance optimization (highly looked upon by Tech Leads)
CREATE INDEX idx_orders_user ON orders(user_id);
CREATE INDEX idx_orders_restaurant ON orders(restaurant_id);
CREATE INDEX idx_orders_timestamp ON orders(order_timestamp);
CREATE INDEX idx_deliveries_rider ON deliveries(rider_id);


-- ===================================================================================================
-- SECTION 2: HIGH-FIDELITY SAMPLE DATA INSERTION (DML)
-- populating our database structure with simulated data aligned with image_a455ce.jpg
-- ===================================================================================================

-- 2.1 Inserting Customers
INSERT INTO users (user_id, user_name, email, signup_date, city, is_premium_member) VALUES
('USR001', 'Anika Rahman', 'anika.rahman@example.com', '2025-10-01', 'Dhaka', TRUE),
('USR002', 'Tanvir Islam', 'tanvir.islam@example.com', '2025-10-15', 'Dhaka', FALSE),
('USR003', 'Zareen Subah', 'zareen.subah@example.com', '2025-11-05', 'Chittagong', TRUE),
('USR004', 'Asif Chowdhury', 'asif.chow@example.com', '2025-11-12', 'Chittagong', FALSE),
('USR005', 'Sajid Hasan', 'sajid.hasan@example.com', '2025-12-01', 'Dhaka', FALSE),
('USR006', 'Marium Begum', 'marium.b@example.com', '2025-12-10', 'Sylhet', TRUE),
('USR007', 'Fahim Ahmed', 'fahim.ahmed@example.com', '2026-01-02', 'Dhaka', FALSE),
('USR008', 'Nabila Tabassum', 'nabila.t@example.com', '2026-01-15', 'Sylhet', FALSE),
('USR009', 'Imran Khan', 'imran.k@example.com', '2026-02-01', 'Chittagong', TRUE),
('USR010', 'Tasnim Jara', 'tasnim.jara@example.com', '2026-02-15', 'Dhaka', FALSE);

-- 2.2 Inserting Restaurants
INSERT INTO restaurants (restaurant_id, restaurant_name, cuisine_type, city, latitude, longitude, partner_tier, average_preparation_time) VALUES
('RES101', 'Burger King Banani', 'Burgers', 'Dhaka', 23.7937, 90.4066, 'Gold', 15),
('RES102', 'Takeout GEC', 'Burgers', 'Chittagong', 22.3592, 91.8214, 'Gold', 20),
('RES103', 'Sultan''s Dine Dhanmondi', 'Biryani', 'Dhaka', 23.7461, 90.3742, 'Gold', 25),
('RES104', 'Chillox Sylhet', 'Burgers', 'Sylhet', 24.8949, 91.8687, 'Silver', 18),
('RES105', 'Pizza Hut Wari', 'Pizza', 'Dhaka', 23.7194, 90.4189, 'Gold', 30),
('RES106', 'Kabab Factory', 'Indian', 'Chittagong', 22.3610, 91.8250, 'Standard', 22),
('RES107', 'Star Kabab Karwan Bazar', 'Local', 'Dhaka', 23.7516, 90.3943, 'Silver', 15),
('RES108', 'Pach Bhai Restaurant', 'Local', 'Sylhet', 24.8990, 91.8720, 'Standard', 12);

-- 2.3 Inserting Riders
INSERT INTO riders (rider_id, rider_name, vehicle_type, average_rating, active_status) VALUES
('RDR201', 'Siddik Ali', 'Motorcycle', 4.85, TRUE),
('RDR202', 'Rony Das', 'Bicycle', 4.60, TRUE),
('RDR203', 'Kamrul Hasan', 'Motorcycle', 4.90, TRUE),
('RDR204', 'Biplob Mia', 'E-Bike', 4.75, TRUE),
('RDR205', 'Mahbub Alam', 'Motorcycle', 4.30, FALSE),
('RDR206', 'Sohel Rana', 'Bicycle', 4.70, TRUE);

-- 2.4 Inserting Orders
-- Structured temporal range to allow time-series analytics (Oct 2025 to Mar 2026)
INSERT INTO orders (order_id, user_id, restaurant_id, order_timestamp, order_status, subtotal_amount, discount_amount, delivery_fee, payment_method, is_first_order) VALUES
-- October 2025
('ORD5001', 'USR001', 'RES101', '2025-10-02 12:30:00', 'Delivered', 450.00, 50.00, 30.00, 'Mobile Wallet', TRUE),
('ORD5002', 'USR002', 'RES103', '2025-10-16 19:45:00', 'Delivered', 1200.00, 100.00, 40.00, 'Cash On Delivery', TRUE),
-- November 2025
('ORD5003', 'USR001', 'RES105', '2025-11-03 21:00:00', 'Delivered', 950.00, 0.00, 50.00, 'Credit Card', FALSE),
('ORD5004', 'USR003', 'RES102', '2025-11-06 13:15:00', 'Delivered', 550.00, 50.00, 30.00, 'Mobile Wallet', TRUE),
('ORD5005', 'USR004', 'RES102', '2025-11-13 14:00:00', 'Cancelled_User', 320.00, 0.00, 30.00, 'Cash On Delivery', TRUE),
-- December 2025
('ORD5006', 'USR002', 'RES103', '2025-12-02 20:30:00', 'Delivered', 850.00, 50.00, 40.00, 'Credit Card', FALSE),
('ORD5007', 'USR005', 'RES107', '2025-12-05 18:00:00', 'Delivered', 600.00, 120.00, 20.00, 'Mobile Wallet', TRUE),
('ORD5008', 'USR006', 'RES108', '2025-12-12 11:30:00', 'Delivered', 350.00, 0.00, 15.00, 'Cash On Delivery', TRUE),
('ORD5009', 'USR001', 'RES103', '2025-12-25 21:15:00', 'Delivered', 1500.00, 200.00, 0.00, 'Credit Card', FALSE),
-- January 2026
('ORD5010', 'USR007', 'RES101', '2026-01-03 13:00:00', 'Delivered', 480.00, 40.00, 30.00, 'Credit Card', TRUE),
('ORD5011', 'USR003', 'RES106', '2026-01-08 19:30:00', 'Delivered', 1100.00, 150.00, 40.00, 'Mobile Wallet', FALSE),
('ORD5012', 'USR008', 'RES104', '2026-01-16 18:45:00', 'Delivered', 380.00, 0.00, 25.00, 'Cash On Delivery', TRUE),
('ORD5013', 'USR002', 'RES107', '2026-01-20 12:00:00', 'Cancelled_Restaurant', 450.00, 0.00, 20.00, 'Mobile Wallet', FALSE),
-- February 2026
('ORD5014', 'USR009', 'RES102', '2026-02-02 14:30:00', 'Delivered', 750.00, 100.00, 30.00, 'Credit Card', TRUE),
('ORD5015', 'USR006', 'RES108', '2026-02-14 19:00:00', 'Delivered', 420.00, 50.00, 15.00, 'Mobile Wallet', FALSE),
('ORD5016', 'USR010', 'RES103', '2026-02-16 20:00:00', 'Delivered', 1400.00, 200.00, 40.00, 'Cash On Delivery', TRUE),
('ORD5017', 'USR001', 'RES105', '2026-02-22 13:00:00', 'Delivered', 900.00, 100.00, 30.00, 'Credit Card', FALSE),
-- March 2026
('ORD5018', 'USR005', 'RES103', '2026-03-01 21:00:00', 'Delivered', 1300.00, 150.00, 40.00, 'Mobile Wallet', FALSE),
('ORD5019', 'USR003', 'RES102', '2026-03-05 18:30:00', 'Delivered', 650.00, 50.00, 30.00, 'Digital Voucher', FALSE),
('ORD5020', 'USR007', 'RES107', '2026-03-12 12:15:00', 'Delivered', 550.00, 50.00, 20.00, 'Cash On Delivery', FALSE);

-- 2.5 Inserting Order Items Details
INSERT INTO order_items (order_id, item_name, quantity, unit_price) VALUES
('ORD5001', 'Classic Beef Burger', 2, 180.00),
('ORD5001', 'Fries', 1, 90.00),
('ORD5002', 'Kacchi Biryani Full', 3, 400.00),
('ORD5003', 'Pepperoni Feast Pizza', 1, 950.00),
('ORD5004', 'Double Cheese Burger', 2, 220.00),
('ORD5004', 'Onion Rings', 1, 110.00),
('ORD5005', 'Spicy Chicken Burger', 1, 200.00),
('ORD5005', 'Fries', 1, 120.00),
('ORD5006', 'Kacchi Biryani Half', 4, 212.50),
('ORD5007', 'Special Beef Sheek Kabab', 3, 150.00),
('ORD5007', 'Rumali Roti', 6, 25.00),
('ORD5008', 'Beef Bhuna with Rice', 2, 175.00),
('ORD5009', 'Morog Polao Special', 5, 300.00),
('ORD5010', 'Crispy Chicken Tender', 3, 160.00),
('ORD5011', 'Chicken Butter Masala', 2, 400.00),
('ORD5011', 'Garlic Naan', 4, 75.00),
('ORD5012', 'Classic Smoked Chicken Burger', 1, 280.00),
('ORD5012', 'Cheese Dip', 2, 50.00),
('ORD5014', 'Takeout Signature Monster', 2, 375.00),
('ORD5015', 'Chicken Khichuri', 2, 210.00),
('ORD5016', 'Mutton Kacchi Platters', 4, 350.00),
('ORD5017', 'Deep Dish Chicken Supreme', 1, 900.00),
('ORD5018', 'Spicy Morog Polao', 4, 325.00),
('ORD5019', 'Cheese Burger Combo', 2, 325.00),
('ORD5020', 'Beef Kabab Roll', 5, 110.00);

-- 2.6 Inserting Deliveries Log
INSERT INTO deliveries (delivery_id, order_id, rider_id, assigned_time, pickup_time, delivery_time, distance_km, delivery_rating) VALUES
('DEL9001', 'ORD5001', 'RDR201', '2025-10-02 12:35:00', '2025-10-02 12:50:00', '2025-10-02 13:05:00', 3.20, 5),
('DEL9002', 'ORD5002', 'RDR203', '2025-10-16 19:50:00', '2025-10-16 20:18:00', '2025-10-16 20:43:00', 5.80, 4),
('DEL9003', 'ORD5003', 'RDR204', '2025-11-03 21:05:00', '2025-11-03 21:32:00', '2025-11-03 21:55:00', 4.50, 5),
('DEL9004', 'ORD5004', 'RDR202', '2025-11-06 13:20:00', '2025-11-06 13:42:00', '2025-11-06 14:15:00', 2.10, 3),
('DEL9005', 'ORD5005', NULL, NULL, NULL, NULL, NULL, NULL), -- Unfulfilled cancellation
('DEL9006', 'ORD5006', 'RDR203', '2025-12-02 20:35:00', '2025-12-02 20:58:00', '2025-12-02 21:24:00', 4.90, 5),
('DEL9007', 'ORD5007', 'RDR201', '2025-12-05 18:05:00', '2025-12-05 18:22:00', '2025-12-05 18:41:00', 1.80, 4),
('DEL9008', 'ORD5008', 'RDR206', '2025-12-12 11:35:00', '2025-12-12 11:48:00', '2025-12-12 12:02:00', 0.95, 5),
('DEL9009', 'ORD5009', 'RDR204', '2025-12-25 21:20:00', '2025-12-25 21:40:00', '2025-12-25 22:05:00', 6.10, 4),
('DEL9010', 'ORD5010', 'RDR201', '2026-01-03 13:05:00', '2026-01-03 13:20:00', '2026-01-03 13:38:00', 2.80, 5),
('DEL9011', 'ORD5011', 'RDR203', '2026-01-08 19:35:00', '2026-01-08 20:00:00', '2026-01-08 20:25:00', 4.20, 2), -- Delayed rating
('DEL9012', 'ORD5012', 'RDR206', '2026-01-16 18:50:00', '2026-01-16 19:08:00', '2026-01-16 19:24:00', 1.50, 5),
('DEL9013', 'ORD5013', NULL, NULL, NULL, NULL, NULL, NULL), -- Restaurant Cancellation
('DEL9014', 'ORD5014', 'RDR202', '2026-02-02 14:35:00', '2026-02-02 14:58:00', '2026-02-02 15:32:00', 3.50, 4),
('DEL9015', 'ORD5015', 'RDR206', '2026-02-14 19:05:00', '2026-02-14 19:18:00', '2026-02-14 19:35:00', 1.20, 5),
('DEL9016', 'ORD5016', 'RDR201', '2026-02-16 20:05:00', '2026-02-16 20:28:00', '2026-02-16 20:53:00', 5.00, 4),
('DEL9017', 'ORD5017', 'RDR204', '2026-02-22 13:05:00', '2026-02-22 13:30:00', '2026-02-22 13:58:00', 3.90, 5),
('DEL9018', 'ORD5018', 'RDR203', '2026-03-01 21:05:00', '2026-03-01 21:28:00', '2026-03-01 21:54:00', 4.40, 5),
('DEL9019', 'ORD5019', 'RDR202', '2026-03-05 18:35:00', '2026-03-05 18:58:00', '2026-03-05 19:30:00', 2.90, 3),
('DEL9020', 'ORD5020', 'RDR201', '2026-03-12 12:20:00', '2026-03-12 12:35:00', '2026-03-12 12:51:00', 1.70, 5);


-- ===================================================================================================
-- SECTION 3: DEEP ADVANCED DATA ANALYTICS & BUSINESS INTELLIGENCE
-- 25 Production-Grade analytical Queries driving Foodpanda Core Strategic Decisions
-- ===================================================================================================

-- ---------------------------------------------------------------------------------------------------
-- QUERY 1: EXECUTIVE KPI DASHBOARD (MONTH-ON-MONTH GROWTH ANALYSIS)
-- Context: Executive-level high-level monthly revenue, order counts, and structural basket sizes.
-- ---------------------------------------------------------------------------------------------------
SELECT 
    TO_CHAR(order_timestamp, 'YYYY-MM') AS report_month,
    COUNT(order_id) AS total_orders,
    COUNT(CASE WHEN order_status = 'Delivered' THEN 1 END) AS successful_orders,
    ROUND((COUNT(CASE WHEN order_status = 'Delivered' THEN 1 END)::NUMERIC / COUNT(order_id) * 100), 2) AS fulfillment_rate_pct,
    SUM(subtotal_amount) AS Gross_Merchandise_Value_GMV,
    SUM(subtotal_amount - discount_amount + delivery_fee) AS Platform_Total_Gross_Revenue,
    ROUND(AVG(subtotal_amount), 2) AS average_order_value_AOV
FROM orders
GROUP BY 1
ORDER BY 1;


-- ---------------------------------------------------------------------------------------------------
-- QUERY 2: MONTH-OVER-MONTH GMV GROWTH RATIO (WINDOW FUNCTION LAG)
-- Context: Measures speed of commercial expansion to track operational momentum.
-- ---------------------------------------------------------------------------------------------------
WITH monthly_gmv AS (
    SELECT 
        TO_CHAR(order_timestamp, 'YYYY-MM') AS sales_month,
        SUM(subtotal_amount) AS current_month_gmv
    FROM orders
    WHERE order_status = 'Delivered'
    GROUP BY 1
)
SELECT 
    sales_month,
    current_month_gmv,
    LAG(current_month_gmv, 1) OVER (ORDER BY sales_month) AS previous_month_gmv,
    ROUND(
        ((current_month_gmv - LAG(current_month_gmv, 1) OVER (ORDER BY sales_month)) / 
        LAG(current_month_gmv, 1) OVER (ORDER BY sales_month) * 100), 2
    ) AS MoM_growth_percentage
FROM monthly_gmv;


-- ---------------------------------------------------------------------------------------------------
-- QUERY 3: COHORT ANALYSIS MATRIX (USER RETENTION TRACKING BY SIGN-UP COHORT)
-- Context: Cohort analysis is highly sought after by recruiters to check lifecycle management logic.
-- ---------------------------------------------------------------------------------------------------
WITH user_cohorts AS (
    SELECT 
        user_id,
        TO_CHAR(signup_date, 'YYYY-MM') AS cohort_month
    FROM users
),
user_activities AS (
    SELECT DISTINCT
        o.user_id,
        TO_CHAR(o.order_timestamp, 'YYYY-MM') AS activity_month,
        -- Calculate intervals in months
        EXTRACT(YEAR FROM AGE(DATE_TRUNC('month', o.order_timestamp), DATE_TRUNC('month', u.signup_date))) * 12 +
        EXTRACT(MONTH FROM AGE(DATE_TRUNC('month', o.order_timestamp), DATE_TRUNC('month', u.signup_date))) AS month_index
    FROM orders o
    JOIN users u ON o.user_id = u.user_id
    WHERE o.order_status = 'Delivered'
)
SELECT 
    c.cohort_month,
    COUNT(DISTINCT c.user_id) AS total_cohort_size,
    COUNT(DISTINCT CASE WHEN a.month_index = 0 THEN a.user_id END) AS Month_0_Active,
    ROUND(COUNT(DISTINCT CASE WHEN a.month_index = 0 THEN a.user_id END)::NUMERIC / COUNT(DISTINCT c.user_id) * 100, 2) || '%' AS Month_0_Retention,
    COUNT(DISTINCT CASE WHEN a.month_index = 1 THEN a.user_id END) AS Month_1_Active,
    ROUND(COUNT(DISTINCT CASE WHEN a.month_index = 1 THEN a.user_id END)::NUMERIC / COUNT(DISTINCT c.user_id) * 100, 2) || '%' AS Month_1_Retention,
    COUNT(DISTINCT CASE WHEN a.month_index = 2 THEN a.user_id END) AS Month_2_Active,
    ROUND(COUNT(DISTINCT CASE WHEN a.month_index = 2 THEN a.user_id END)::NUMERIC / COUNT(DISTINCT c.user_id) * 100, 2) || '%' AS Month_2_Retention
FROM user_cohorts c
LEFT JOIN user_activities a ON c.user_id = a.user_id
GROUP BY c.cohort_month
ORDER BY c.cohort_month;


-- ---------------------------------------------------------------------------------------------------
-- QUERY 4: RFM CUSTOMER SEGMENTATION (RECENCY, FREQUENCY, MONETARY)
-- Context: Classify foodpanda customers into strategic actionable groups based on behavioral transactional telemetry.
-- ---------------------------------------------------------------------------------------------------
WITH customer_rfm_metrics AS (
    SELECT 
        user_id,
        -- Recency: Days since last completed transaction relative to mock system evaluation date ('2026-03-15')
        EXTRACT(DAY FROM ('2026-03-15 00:00:00'::TIMESTAMP - MAX(order_timestamp))) AS recency,
        COUNT(order_id) AS frequency,
        SUM(subtotal_amount) AS monetary
    FROM orders
    WHERE order_status = 'Delivered'
    GROUP BY user_id
),
rfm_scores AS (
    SELECT 
        user_id,
        recency,
        frequency,
        monetary,
        NTILE(4) OVER (ORDER BY recency ASC) AS r_score,     -- Lower days since last purchase = higher rank (4)
        NTILE(4) OVER (ORDER BY frequency DESC) AS f_score,   -- Higher transaction count = higher rank (4)
        NTILE(4) OVER (ORDER BY monetary DESC) AS m_score     -- Higher spending patterns = higher rank (4)
    FROM customer_rfm_metrics
)
SELECT 
    user_id,
    recency,
    frequency,
    monetary,
    r_score,
    f_score,
    m_score,
    (r_score + f_score + m_score) AS aggregate_rfm,
    CASE 
        WHEN (r_score + f_score + m_score) >= 10 THEN 'Core Champions (VIP)'
        WHEN r_score >= 3 AND f_score >= 3 THEN 'Loyal Cultivators'
        WHEN r_score <= 2 AND f_score >= 3 THEN 'At Risk Active Seekers'
        WHEN r_score <= 1 THEN 'Hibernating Lost Customers'
        ELSE 'Casual Trial Buyers'
    END AS strategic_segmentation
FROM rfm_scores
ORDER BY aggregate_rfm DESC, monetary DESC;


-- ---------------------------------------------------------------------------------------------------
-- QUERY 5: DELAYED LOGISTICS PERFORMANCE REPORT (RIDER SLA COMPLIANCE)
-- Context: Identifies logistical lag by analyzing SLA breaches between actual vs estimated preparation.
-- ---------------------------------------------------------------------------------------------------
SELECT 
    d.delivery_id,
    o.order_id,
    r.restaurant_name,
    rd.rider_name,
    rd.vehicle_type,
    -- Step 1: Prep phase duration (order to pickup)
    EXTRACT(EPOCH FROM (d.pickup_time - o.order_timestamp)) / 60 AS actual_preparation_time_minutes,
    r.average_preparation_time AS base_sla_minutes,
    -- Step 2: Transit phase duration (pickup to delivery)
    EXTRACT(EPOCH FROM (d.delivery_time - d.pickup_time)) / 60 AS actual_transit_time_minutes,
    ROUND(d.distance_km, 2) AS distance_km,
    -- Step 3: SLA Breach classification
    CASE 
        WHEN (EXTRACT(EPOCH FROM (d.pickup_time - o.order_timestamp)) / 60) > r.average_preparation_time THEN 'SLA BREACH: RESTAURANT DELAY'
        WHEN (EXTRACT(EPOCH FROM (d.delivery_time - d.pickup_time)) / 60) > (d.distance_km * 8) THEN 'SLA BREACH: RIDER DELAY'
        ELSE 'SLA COMPLIANT'
    END AS operational_sla_status
FROM deliveries d
JOIN orders o ON d.order_id = o.order_id
JOIN restaurants r ON o.restaurant_id = r.restaurant_id
LEFT JOIN riders rd ON d.rider_id = rd.rider_id
WHERE o.order_status = 'Delivered'
ORDER BY actual_preparation_time_minutes DESC;


-- ---------------------------------------------------------------------------------------------------
-- QUERY 6: HOURLY HEATMAP BOTTLE-NECK ANALYSIS (ORDER LOAD VS DELIV_TIME)
-- Context: Finding sweet spots for surge pricing or rider dispatch capacity scheduling.
-- ---------------------------------------------------------------------------------------------------
SELECT 
    EXTRACT(HOUR FROM o.order_timestamp) AS order_hour,
    COUNT(o.order_id) AS total_orders_placed,
    ROUND(AVG(o.subtotal_amount), 2) AS average_basket_amount,
    ROUND(AVG(EXTRACT(EPOCH FROM (d.delivery_time - o.order_timestamp)) / 60), 2) AS avg_click_to_door_time_mins,
    ROUND(AVG(d.distance_km), 2) AS avg_delivery_distance_km,
    -- Speed indexing (Minutes taken to deliver 1 KM)
    ROUND(AVG(EXTRACT(EPOCH FROM (d.delivery_time - d.pickup_time)) / 60) / NULLIF(AVG(d.distance_km), 0), 2) AS mins_per_km_speed
FROM orders o
JOIN deliveries d ON o.order_id = d.order_id
WHERE o.order_status = 'Delivered'
GROUP BY 1
ORDER BY total_orders_placed DESC;


-- ---------------------------------------------------------------------------------------------------
-- QUERY 7: RESTAURANT CONTRIBUTION MARGINS AND PLATFORM TAKE-RATE REVENUE
-- Context: Financial analytics to determine net margin profitability metrics.
-- ---------------------------------------------------------------------------------------------------
WITH platform_financials AS (
    SELECT 
        r.restaurant_id,
        r.restaurant_name,
        r.partner_tier,
        COUNT(o.order_id) AS items_sold_count,
        SUM(o.subtotal_amount) AS total_gmv,
        -- Commission rate calculation base on partner tier logic
        CASE 
            WHEN r.partner_tier = 'Gold' THEN 0.25
            WHEN r.partner_tier = 'Silver' THEN 0.20
            ELSE 0.15
        END AS commission_pct,
        SUM(o.discount_amount) AS promo_absorbed
    FROM restaurants r
    JOIN orders o ON r.restaurant_id = o.restaurant_id
    WHERE o.order_status = 'Delivered'
    GROUP BY r.restaurant_id, r.restaurant_name, r.partner_tier
)
SELECT 
    restaurant_name,
    partner_tier,
    items_sold_count,
    total_gmv,
    commission_pct * 100 || '%' AS tier_take_rate,
    ROUND(total_gmv * commission_pct, 2) AS gross_commission_revenue,
    -- Net partner payouts after substracting platform deductions and promos
    ROUND(total_gmv - (total_gmv * commission_pct) - (promo_absorbed * 0.4), 2) AS estimated_payout_to_restaurant,
    ROUND((total_gmv * commission_pct) - (promo_absorbed * 0.6), 2) AS foodpanda_estimated_net_margin
FROM platform_financials
ORDER BY foodpanda_estimated_net_margin DESC;


-- ---------------------------------------------------------------------------------------------------
-- QUERY 8: PROMO CODE EXPLOITER DETECTION AND ABUSE SEGMENTATION
-- Context: Risk mitigation query looking for high discount affinity behaviors.
-- ---------------------------------------------------------------------------------------------------
SELECT 
    u.user_id,
    u.user_name,
    COUNT(o.order_id) AS lifetime_orders,
    SUM(o.subtotal_amount) AS gross_spend_amount,
    SUM(o.discount_amount) AS promo_discount_availed,
    ROUND((SUM(o.discount_amount) / NULLIF(SUM(o.subtotal_amount), 0)) * 100, 2) AS discount_penetration_ratio,
    COUNT(CASE WHEN o.discount_amount > 0 THEN 1 END) AS orders_using_coupons,
    CASE 
        WHEN SUM(o.discount_amount) / NULLIF(SUM(o.subtotal_amount), 0) >= 0.35 THEN 'HIGH-RISK: PROMO EXPLOITER'
        WHEN SUM(o.discount_amount) / NULLIF(SUM(o.subtotal_amount), 0) BETWEEN 0.15 AND 0.34 THEN 'NORMAL: VALUE SEEKER'
        ELSE 'HIGH-VALUE: ORGANIC CUSTOMER'
    END AS customer_profitability_tier
FROM users u
JOIN orders o ON u.user_id = o.user_id
GROUP BY u.user_id, u.user_name
HAVING COUNT(o.order_id) >= 2
ORDER BY discount_penetration_ratio DESC;


-- ---------------------------------------------------------------------------------------------------
-- QUERY 9: RIDER FLEET PERFORMANCE AND SATISFACTION INDEX
-- Context: Operational efficiency scoring tool for continuous logistics optimizations.
-- ---------------------------------------------------------------------------------------------------
SELECT 
    r.rider_id,
    r.rider_name,
    r.vehicle_type,
    COUNT(d.delivery_id) AS total_deliveries_assigned,
    COUNT(CASE WHEN d.delivery_time IS NOT NULL THEN 1 END) AS successful_deliveries,
    -- Calculation of average delivery speed
    ROUND(AVG(d.distance_km / (EXTRACT(EPOCH FROM (d.delivery_time - d.pickup_time)) / 3600)), 2) AS avg_speed_km_hour,
    ROUND(AVG(d.delivery_rating), 1) AS rider_avg_operational_score,
    r.average_rating AS platform_historical_rating,
    -- Alerts for poor-performing or deteriorating riders
    CASE 
        WHEN AVG(d.delivery_rating) < 4.0 THEN 'ALERT: DECREASED SATISFACTION'
        WHEN AVG(d.delivery_rating) >= 4.7 THEN 'REWARD: PLATINUM LOGISTICS STATUS'
        ELSE 'STABLE'
    END AS performance_milestone_action
FROM riders r
LEFT JOIN deliveries d ON r.rider_id = d.rider_id
GROUP BY r.rider_id, r.rider_name, r.vehicle_type, r.average_rating
ORDER BY total_deliveries_assigned DESC, avg_speed_km_hour DESC;


-- ---------------------------------------------------------------------------------------------------
-- QUERY 10: USER DISENGAGEMENT ANALYSIS (CHURN RISK ENGINE)
-- Context: Proactively identifies users showing dropping order patterns.
-- ---------------------------------------------------------------------------------------------------
WITH user_timeline_analysis AS (
    SELECT 
        u.user_id,
        u.user_name,
        u.signup_date,
        COUNT(o.order_id) AS total_historical_orders,
        MAX(o.order_timestamp) AS last_order_date,
        -- Window function to pull the order timestamp previous to the latest one
        LAG(o.order_timestamp, 1) OVER (PARTITION BY o.user_id ORDER BY o.order_timestamp ASC) AS second_to_last_order_date
    FROM users u
    LEFT JOIN orders o ON u.user_id = o.user_id AND o.order_status = 'Delivered'
    GROUP BY u.user_id, u.user_name, u.signup_date, o.order_timestamp
)
SELECT 
    user_id,
    user_name,
    total_historical_orders,
    last_order_date,
    EXTRACT(DAY FROM ('2026-03-15 00:00:00'::TIMESTAMP - last_order_date)) AS days_since_last_order,
    -- Interval trend calculation
    ROUND(EXTRACT(EPOCH FROM (last_order_date - second_to_last_order_date)) / 86400, 1) AS last_purchase_cycle_days,
    CASE 
        WHEN EXTRACT(DAY FROM ('2026-03-15 00:00:00'::TIMESTAMP - last_order_date)) > 60 THEN 'CRITICAL: PROBABLY CHURNED'
        WHEN EXTRACT(DAY FROM ('2026-03-15 00:00:00'::TIMESTAMP - last_order_date)) BETWEEN 30 AND 60 THEN 'HIGH WARNING: COLD ENGAGEMENT'
        ELSE 'RETAINED: ENERGETIC BUYER'
    END AS platform_churn_probability
FROM user_timeline_analysis
ORDER BY days_since_last_order DESC NULLS LAST;


-- ---------------------------------------------------------------------------------------------------
-- QUERY 11: GEOGRAPHICAL PERFORMANCE MATRIX BY CITY
-- Context: Determines local strategic targets to identify hyper-local product-market fit.
-- ---------------------------------------------------------------------------------------------------
SELECT 
    u.city AS geographical_location,
    COUNT(DISTINCT u.user_id) AS platform_active_consumers,
    COUNT(o.order_id) AS local_order_count,
    ROUND(COUNT(o.order_id)::NUMERIC / COUNT(DISTINCT u.user_id), 2) AS order_density_per_customer,
    SUM(o.subtotal_amount) AS total_regional_gmv,
    ROUND(AVG(o.subtotal_amount), 2) AS regional_average_basket_value,
    -- Regional delivery efficiency rating average
    ROUND(AVG(d.delivery_rating), 2) AS regional_delivery_experience_score
FROM users u
LEFT JOIN orders o ON u.user_id = o.user_id
LEFT JOIN deliveries d ON o.order_id = d.order_id
GROUP BY u.city
ORDER BY total_regional_gmv DESC;


-- ---------------------------------------------------------------------------------------------------
-- QUERY 12: DINNER VS LUNCH REVENUE AND VOLUMETRIC SPLIT
-- Context: Operational optimization for targeted marketing campaigns by daytime parts.
-- ---------------------------------------------------------------------------------------------------
SELECT 
    CASE 
        WHEN EXTRACT(HOUR FROM order_timestamp) BETWEEN 11 AND 15 THEN 'LUNCH PERIOD (11AM - 3PM)'
        WHEN EXTRACT(HOUR FROM order_timestamp) BETWEEN 17 AND 22 THEN 'DINNER PERIOD (5PM - 10PM)'
        WHEN EXTRACT(HOUR FROM order_timestamp) BETWEEN 23 AND 4 THEN 'LATE-NIGHT (11PM - 4AM)'
        ELSE 'OTHER OFF-PEAK HOURS'
    END AS mealtime_daypart,
    COUNT(order_id) AS count_orders,
    SUM(subtotal_amount) AS revenue_collected,
    ROUND((COUNT(order_id)::NUMERIC / (SELECT COUNT(*) FROM orders) * 100), 2) AS distribution_ratio_pct,
    ROUND(AVG(subtotal_amount), 2) AS avg_meal_value
FROM orders
GROUP BY 1
ORDER BY revenue_collected DESC;


-- ---------------------------------------------------------------------------------------------------
-- QUERY 13: CUISINE POPULARITY AND STRATEGIC BASKET CROSS-SELL INDEX
-- Context: Helps category managers optimize banner placement, pricing and merchant on-boarding.
-- ---------------------------------------------------------------------------------------------------
SELECT 
    r.cuisine_type,
    COUNT(o.order_id) AS transaction_frequency,
    SUM(oi.quantity) AS total_items_served,
    SUM(o.subtotal_amount) AS gross_sales_value,
    -- Cross-sell index: avg items per customer transaction inside cuisine category
    ROUND(AVG(oi.quantity), 2) AS average_cross_sell_depth,
    ROUND((SUM(o.subtotal_amount) / (SELECT SUM(subtotal_amount) FROM orders WHERE order_status = 'Delivered') * 100), 2) AS cuisine_market_share_pct
FROM restaurants r
JOIN orders o ON r.restaurant_id = o.restaurant_id
JOIN order_items oi ON o.order_id = oi.order_id
WHERE o.order_status = 'Delivered'
GROUP BY r.cuisine_type
ORDER BY gross_sales_value DESC;


-- ---------------------------------------------------------------------------------------------------
-- QUERY 14: PARETO PRINCIPLE (80/20 RULE) IN RESTAURANT PARTNER NETWORK
-- Context: Checks whether 80% of revenue is driven by top 20% of restaurateurs.
-- ---------------------------------------------------------------------------------------------------
WITH restaurant_performance AS (
    SELECT 
        restaurant_id,
        restaurant_name,
        SUM(subtotal_amount) AS total_restaurant_revenue,
        SUM(SUM(subtotal_amount)) OVER () AS system_total_revenue,
        -- Running accumulated total
        SUM(SUM(subtotal_amount)) OVER (ORDER BY SUM(subtotal_amount) DESC ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative_revenue
    FROM orders
    WHERE order_status = 'Delivered'
    GROUP BY restaurant_id, restaurant_name
)
SELECT 
    restaurant_name,
    total_restaurant_revenue,
    ROUND((total_restaurant_revenue / system_total_revenue * 100), 2) AS direct_revenue_share_pct,
    ROUND((cumulative_revenue / system_total_revenue * 100), 2) AS cumulative_revenue_share_pct,
    CASE 
        WHEN (cumulative_revenue / system_total_revenue * 100) <= 80.00 THEN 'PARETO DRIVER: TOP 80%'
        ELSE 'LONG TAIL MERCHANDISE'
    END AS pareto_classification
FROM restaurant_performance
ORDER BY total_restaurant_revenue DESC;


-- ---------------------------------------------------------------------------------------------------
-- QUERY 15: FIRST-TIME ORDER CONVERSION IMPACT ON RETENTION
-- Context: Validates the business effectiveness of signup discount vouchers.
-- ---------------------------------------------------------------------------------------------------
SELECT 
    u.is_premium_member,
    COUNT(DISTINCT u.user_id) AS consumer_count,
    SUM(CASE WHEN o.is_first_order = TRUE THEN 1 ELSE 0 END) AS total_first_orders,
    ROUND(AVG(o.subtotal_amount), 2) AS average_basket_amount,
    -- Analysis of first time order cancellations vs recurring order cancellations
    ROUND((COUNT(CASE WHEN o.order_status IN ('Cancelled_User', 'Cancelled_Restaurant') THEN 1 END)::NUMERIC / COUNT(o.order_id) * 100), 2) AS cancel_attrition_pct
FROM users u
LEFT JOIN orders o ON u.user_id = o.user_id
GROUP BY u.is_premium_member;


-- ---------------------------------------------------------------------------------------------------
-- QUERY 16: CRITICAL PATH ANALYSIS (ORDER LIFE-CYCLE MILESTONES)
-- Context: Breaks down operational friction down to seconds to locate internal delays.
-- ---------------------------------------------------------------------------------------------------
SELECT 
    d.order_id,
    o.order_timestamp AS step1_order_placed,
    d.assigned_time AS step2_rider_assigned,
    d.pickup_time AS step3_merchant_handover,
    d.delivery_time AS step4_customer_received,
    -- Durations (Minutes)
    ROUND(EXTRACT(EPOCH FROM (d.assigned_time - o.order_timestamp)) / 60, 2) AS assignation_lag_mins,
    ROUND(EXTRACT(EPOCH FROM (d.pickup_time - d.assigned_time)) / 60, 2) AS dispatch_transit_mins,
    ROUND(EXTRACT(EPOCH FROM (d.delivery_time - d.pickup_time)) / 60, 2) AS final_mile_transit_mins,
    -- Cumulative End-to-End time
    ROUND(EXTRACT(EPOCH FROM (d.delivery_time - o.order_timestamp)) / 60, 2) AS total_end_to_end_delivery_mins
FROM deliveries d
JOIN orders o ON d.order_id = o.order_id
WHERE o.order_status = 'Delivered'
ORDER BY total_end_to_end_delivery_mins DESC;


-- ---------------------------------------------------------------------------------------------------
-- QUERY 17: RUNNING TOTAL CUMULATIVE REVENUE PER CITY (ANALYTICAL WINDOWING)
-- Context: Shows the timeline build up of regional revenues day by day.
-- ---------------------------------------------------------------------------------------------------
SELECT 
    u.city,
    DATE(o.order_timestamp) AS calendar_date,
    SUM(o.subtotal_amount) AS daily_revenue,
    -- Cumulative running sum partitioned by city and ordered by day
    SUM(SUM(o.subtotal_amount)) OVER (
        PARTITION BY u.city 
        ORDER BY DATE(o.order_timestamp) 
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS running_cumulative_revenue
FROM orders o
JOIN users u ON o.user_id = u.user_id
WHERE o.order_status = 'Delivered'
GROUP BY u.city, DATE(o.order_timestamp)
ORDER BY u.city, calendar_date;


-- ---------------------------------------------------------------------------------------------------
-- QUERY 18: RESTAURANT RETENTION RATING VS CANCELLED RATE ANOMALY DETECTION
-- Context: Flags operational quality concerns on partners.
-- ---------------------------------------------------------------------------------------------------
SELECT 
    r.restaurant_id,
    r.restaurant_name,
    COUNT(o.order_id) AS total_placed_orders,
    COUNT(CASE WHEN o.order_status = 'Cancelled_Restaurant' THEN 1 END) AS restaurant_initiated_cancellations,
    ROUND(
        (COUNT(CASE WHEN o.order_status = 'Cancelled_Restaurant' THEN 1 END)::NUMERIC / NULLIF(COUNT(o.order_id), 0) * 100), 2
    ) AS merchant_rejection_rate_pct,
    r.average_preparation_time,
    -- Comparing with regional benchmarks
    ROUND(AVG(r.average_preparation_time) OVER (PARTITION BY r.city), 1) AS regional_avg_prep_benchmark
FROM restaurants r
LEFT JOIN orders o ON r.restaurant_id = o.restaurant_id
GROUP BY r.restaurant_id, r.restaurant_name, r.average_preparation_time, r.city
ORDER BY merchant_rejection_rate_pct DESC;


-- ---------------------------------------------------------------------------------------------------
-- QUERY 19: REPEAT PURCHASER VS ONE-TIME WONDER ANALYSIS
-- Context: Highlights baseline marketing efficiency in bringing back organic customers.
-- ---------------------------------------------------------------------------------------------------
WITH repeat_counts AS (
    SELECT 
        user_id,
        COUNT(order_id) AS total_orders
    FROM orders
    WHERE order_status = 'Delivered'
    GROUP BY user_id
)
SELECT 
    CASE 
        WHEN total_orders = 1 THEN 'One-Time Experimenters'
        WHEN total_orders BETWEEN 2 AND 4 THEN 'Active Repeat Purchasers'
        ELSE 'Heavy Platform Believers (Power Users)'
    END AS purchase_frequency_tier,
    COUNT(user_id) AS total_customers_count,
    ROUND((COUNT(user_id)::NUMERIC / (SELECT COUNT(DISTINCT user_id) FROM orders)) * 100, 2) AS ratio_of_base_pct
FROM repeat_counts
GROUP BY 1
ORDER BY total_customers_count DESC;


-- ---------------------------------------------------------------------------------------------------
-- QUERY 20: HIGH VALUE CART BASKET ANALYSIS (N-TILE GROUPS)
-- Context: Segments average check values into standard operational deciles.
-- ---------------------------------------------------------------------------------------------------
SELECT 
    order_id,
    subtotal_amount,
    NTILE(10) OVER (ORDER BY subtotal_amount DESC) AS spend_decile,
    CASE 
        WHEN subtotal_amount >= 1000.00 THEN 'Premium Cart (High Tier)'
        WHEN subtotal_amount BETWEEN 500.00 AND 999.99 THEN 'Standard Cart (Mid Tier)'
        ELSE 'Budget Cart (Economy Tier)'
    END AS basket_tier_profile
FROM orders
WHERE order_status = 'Delivered'
ORDER BY subtotal_amount DESC;


-- ---------------------------------------------------------------------------------------------------
-- QUERY 21: FINANCIAL VOUCHER PENETRATION BY PREFERRED PAYMENT SYSTEM
-- Context: Negotiating commercial fee discounts with payment provider alliances.
-- ---------------------------------------------------------------------------------------------------
SELECT 
    payment_method,
    COUNT(order_id) AS transaction_volume,
    SUM(subtotal_amount) AS raw_gmv,
    SUM(discount_amount) AS discounted_amount_claimed,
    ROUND((SUM(discount_amount) / NULLIF(SUM(subtotal_amount), 0) * 100), 2) AS voucher_subsidy_pct,
    ROUND(AVG(subtotal_amount), 2) AS average_ticket_size
FROM orders
GROUP BY payment_method
ORDER BY transaction_volume DESC;


-- ---------------------------------------------------------------------------------------------------
-- QUERY 22: RIDER SPEED AND VEHICLE TYPE EFFICIENCY ANALYSIS
-- Context: Helps operations team decide fleet split configurations.
-- ---------------------------------------------------------------------------------------------------
SELECT 
    rd.vehicle_type,
    COUNT(d.delivery_id) AS completed_orders,
    ROUND(AVG(d.distance_km), 2) AS avg_delivery_distance_km,
    ROUND(AVG(EXTRACT(EPOCH FROM (d.delivery_time - d.pickup_time)) / 60), 2) AS avg_transit_time_minutes,
    -- Standard Speed logic
    ROUND(AVG(d.distance_km) / (AVG(EXTRACT(EPOCH FROM (d.delivery_time - d.pickup_time)) / 3600)), 2) AS effective_velocity_kph
FROM deliveries d
JOIN riders rd ON d.rider_id = rd.rider_id
WHERE d.delivery_time IS NOT NULL
GROUP BY rd.vehicle_type
ORDER BY effective_velocity_kph DESC;


-- ---------------------------------------------------------------------------------------------------
-- QUERY 23: CORRELATION INSIGHTS: DELIV_RATING VS SPEED DELAY
-- Context: Validates if delayed delivery strongly impacts user satisfaction rating.
-- ---------------------------------------------------------------------------------------------------
SELECT 
    d.delivery_rating,
    COUNT(d.delivery_id) AS total_deliveries_analyzed,
    ROUND(AVG(EXTRACT(EPOCH FROM (d.delivery_time - o.order_timestamp)) / 60), 2) AS avg_click_to_door_time_mins,
    ROUND(AVG(EXTRACT(EPOCH FROM (d.pickup_time - o.order_timestamp)) / 60), 2) AS avg_restaurant_delay_mins,
    ROUND(AVG(d.distance_km), 2) AS average_distance_km
FROM deliveries d
JOIN orders o ON d.order_id = o.order_id
WHERE d.delivery_rating IS NOT NULL
GROUP BY d.delivery_rating
ORDER BY d.delivery_rating DESC;


-- ---------------------------------------------------------------------------------------------------
-- QUERY 24: TOP POPULAR ADD-ON / CROSS-SELL PAIRING CHOICES (BASKET ANALYSIS)
-- Context: Identify frequently-bought-together item structures to build bundle discounts.
-- ---------------------------------------------------------------------------------------------------
WITH order_item_lists AS (
    SELECT 
        order_id,
        item_name
    FROM order_items
)
SELECT 
    a.item_name AS anchor_product,
    b.item_name AS recommended_companion,
    COUNT(*) AS absolute_pairing_frequency
FROM order_item_lists a
JOIN order_item_lists b ON a.order_id = b.order_id AND a.item_name < b.item_name
GROUP BY 1, 2
ORDER BY absolute_pairing_frequency DESC
LIMIT 5;


-- ---------------------------------------------------------------------------------------------------
-- QUERY 25: RETENTION DRIVER: PREMIUM SUBSCRIPTION VALUE ANALYSIS
-- Context: Measures incremental lift generated by premium membership program.
-- ---------------------------------------------------------------------------------------------------
SELECT 
    u.is_premium_member,
    COUNT(DISTINCT u.user_id) AS user_count,
    COUNT(o.order_id) AS order_count,
    SUM(o.subtotal_amount) AS aggregate_gmv,
    ROUND(AVG(o.subtotal_amount), 2) AS average_basket_amount,
    ROUND(AVG(o.delivery_fee), 2) AS average_delivery_fee_paid,
    ROUND(AVG(d.delivery_rating), 2) AS consumer_satisfaction_rating
FROM users u
LEFT JOIN orders o ON u.user_id = o.user_id
LEFT JOIN deliveries d ON o.order_id = d.order_id
WHERE o.order_status = 'Delivered'
GROUP BY u.is_premium_member;

-- ===================================================================================================
-- END OF PORTFOLIO SCRIPT
-- ===================================================================================================
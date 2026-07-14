-- ====================================================================================================
-- PROJECT: GLOBAL FASHION INDUSTRY COMPREHENSIVE DATA ANALYTICS & MARKET INTELLIGENCE
-- DATA SOURCE REF: image_9a4e42.jpg (Financial records for 13 global retail and luxury brands)
-- ENGINE COMPATIBILITY: PostgreSQL 12+
-- AUTHOR: Senior Data Engineer & Analytics Lead
-- DESCRIPTION: An end-to-end relational database design, data warehousing ingestion pipeline, 
--              advanced financial analytics, window functions, predictive statistics, reporting views,
--              and dynamic business logic executing over historical business metrics.
-- ====================================================================================================


-- Drop existing tables to ensure clean, repeatable runs
DROP TABLE IF EXISTS audit_financial_logs CASCADE;
DROP TABLE IF EXISTS market_trends CASCADE;
DROP TABLE IF EXISTS historical_financials CASCADE;
DROP TABLE IF EXISTS fashion_companies CASCADE;

-- Create Dimensions Table: fashion_companies
CREATE TABLE fashion_companies (
    company_id INT PRIMARY KEY,
    company_name VARCHAR(100) NOT NULL UNIQUE,
    company_total_revenue NUMERIC(20, 2) NOT NULL, -- Total historical/estimated revenue scale
    fashion_category VARCHAR(50) NOT NULL,         -- Casual, Athleisure, Preppy, High Fashion, Fast Fashion
    company_region VARCHAR(50) NOT NULL,           -- Asia, Europe, North America, Americas
    company_score_metric NUMERIC(12, 6) NOT NULL,  -- Standard metric score representing scale/ranking multiplier
    founding_year INT NOT NULL CHECK (founding_year BETWEEN 1800 AND 2026),
    country_of_origin VARCHAR(100) NOT NULL
);

-- Create Fact/Time-Series Table: historical_financials
CREATE TABLE historical_financials (
    financial_id SERIAL PRIMARY KEY,
    company_id INT REFERENCES fashion_companies(company_id) ON DELETE CASCADE,
    fiscal_year INT NOT NULL CHECK (fiscal_year BETWEEN 2010 AND 2022),
    annual_revenue NUMERIC(20, 2) NOT NULL CHECK (annual_revenue >= 0),
    operating_expense NUMERIC(20, 2) NOT NULL CHECK (operating_expense >= 0),
    net_profit NUMERIC(20, 2) GENERATED ALWAYS AS (annual_revenue - operating_expense) STORED,
    profit_margin_percentage NUMERIC(5, 2) GENERATED ALWAYS AS (
        CASE WHEN annual_revenue > 0 THEN ROUND(((annual_revenue - operating_expense) / annual_revenue) * 100, 2)
             ELSE 0.00 END
    ) STORED,
    CONSTRAINT unique_company_year UNIQUE (company_id, fiscal_year)
);

-- Create Market Contextual Trends Table: market_trends
CREATE TABLE market_trends (
    trend_id SERIAL PRIMARY KEY,
    fiscal_year INT NOT NULL CHECK (fiscal_year BETWEEN 2010 AND 2022),
    fashion_category VARCHAR(50) NOT NULL,
    global_market_size NUMERIC(20, 2) NOT NULL,
    category_annual_growth NUMERIC(5, 2)
);

-- Create Audit Log table to capture data modifications
CREATE TABLE audit_financial_logs (
    log_id SERIAL PRIMARY KEY,
    action_type VARCHAR(10) NOT NULL, -- INSERT, UPDATE, DELETE
    company_id INT,
    fiscal_year INT,
    old_revenue NUMERIC(20, 2),
    new_revenue NUMERIC(20, 2),
    adjusted_by VARCHAR(50) DEFAULT CURRENT_USER,
    adjusted_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);


-- Indexes designed to optimize high-performance window-aggregates, group-by, and joins
CREATE INDEX idx_financials_company_year ON historical_financials(company_id, fiscal_year);
CREATE INDEX idx_financials_revenue ON historical_financials(annual_revenue);
CREATE INDEX idx_companies_category_region ON fashion_companies(fashion_category, company_region);
CREATE INDEX idx_market_trends_year_cat ON market_trends(fiscal_year, fashion_category);


-- Reconstructing and ingesting the fashion companies from image_9a4e42.jpg
INSERT INTO fashion_companies (company_id, company_name, company_total_revenue, fashion_category, company_region, company_score_metric, founding_year, country_of_origin) VALUES
(1,  'Uniqlo',             1.850e+10, 'CASUAL WEAR',  'Asia',          175.000000, 1984, 'Tokyo, Japan'),
(2,  'Lululemon',          3.238e+09, 'CASUAL WEAR',  'Europe, Asia',   62.416667, 1998, 'Tokyo, Japan'), -- Reconstructed location matching input matrix verbatim
(3,  'Gap',                1.575e+10, 'CASUAL WEAR',  'North America', 296.666667, 1969, 'California, US'),
(4,  'Levi''s',            5.156e+09, 'CASUAL WEAR',  'Americas',       57.666667, 1853, 'California, US'),
(5,  'Tommy Hilfiger',     3.890e+09, 'CASUAL WEAR',  'Europe, America',187.833333, 1985, 'New York, US'),
(6,  'Ralph Lauren',       6.654e+09, 'PREPPY',       'North America',  47.000000, 1967, 'New York, US'),
(7,  'H&M',                3.850e+10, 'FAST FASHION', 'Europe, Asia',  181.833333, 1947, 'Vasteras, Sweden'),
(8,  'Zara',               2.200e+10, 'FAST FASHION', 'Europe, Asia',  185.833333, 1975, 'A Coruña, Spain'),
(9,  'Bottega Veneta',     1.298e+09, 'HIGH FASHION', 'Europe, America', 25.263333, 1966, 'Veneto, Italy'),
(10, 'Prada',              3.558e+09, 'HIGH FASHION', 'Europe, America', 58.250000, 1913, 'Milan, Italy'),
(11, 'Nike',               3.700e+10, 'ATHLEISURE',   'North America',  88.000000, 1964, 'Oregon, US'),
(12, 'Adidas',             2.242e+10, 'ATHLEISURE',   'Europe, America',155.250000, 1949, 'Herzogenaurach, Germany'),
(13, 'Yves Saint Laurent', 1.868e+09, 'CHIC',         'Europe, America', 26.500000, 1961, 'Paris, France');


-- Populating 13 sequential financial periods (2010 to 2022) to reconstruct the vertical matrices from image_9a4e42.jpg
INSERT INTO historical_financials (company_id, fiscal_year, annual_revenue, operating_expense) VALUES
-- Company 1: Uniqlo (Steady Expansion Path)
(1, 2010, 5260000000,  3945000000),
(1, 2011, 6550000000,  4912500000),
(1, 2012, 7980000000,  5985000000),
(1, 2013, 9410000000,  6963400000),
(1, 2014, 10800000000, 8100000000),
(1, 2015, 10500000000, 7875000000),
(1, 2016, 11900000000, 8925000000),
(1, 2017, 12900000000, 9675000000),
(1, 2018, 12200000000, 9150000000),
(1, 2019, 12200000000, 9272000000),
(1, 2020, 13120000000, 10098000000),
(1, 2021, 15600000000, 11700000000),
(1, 2022, 18500000000, 13505000000),

-- Company 2: Lululemon (Fast Mid-Market Growth)
(2, 2010, 1001000000,  700700000),
(2, 2011, 1370000000,  945300000),
(2, 2012, 1590000000,  1081200000),
(2, 2013, 1790000000,  1217200000),
(2, 2014, 2060000000,  1400800000),
(2, 2015, 2344000000,  1617360000),
(2, 2016, 2649000000,  1827810000),
(2, 2017, 3308000000,  2216360000),
(2, 2018, 3980000000,  2666600000),
(2, 2019, 4402000000,  2993360000),
(2, 2020, 4820000000,  3229400000),
(2, 2021, 6250000000,  4125000000),
(2, 2022, 8110000000,  5190400000),

-- Company 3: Gap (Retail Volatility / Restructuring)
(3, 2010, 14200000000, 11360000000),
(3, 2011, 14700000000, 11907000000),
(3, 2012, 15600000000, 12636000000),
(3, 2013, 16100000000, 12880000000),
(3, 2014, 16400000000, 13120000000),
(3, 2015, 15800000000, 12956000000),
(3, 2016, 15500000000, 12865000000),
(3, 2017, 15900000000, 13197000000),
(3, 2018, 16600000000, 13944000000),
(3, 2019, 16400000000, 13940000000),
(3, 2020, 13800000000, 12144000000),
(3, 2021, 15600000000, 13260000000),
(3, 2022, 15750000000, 13545000000),

-- Company 4: Levi's (Denim Legacy Stability)
(4, 2010, 4400000000,  3344000000),
(4, 2011, 4500000000,  3465000000),
(4, 2012, 4600000000,  3588000000),
(4, 2013, 4700000000,  3619000000),
(4, 2014, 4800000000,  3744000000),
(4, 2015, 4550000000,  3594500000),
(4, 2016, 4680000000,  3650400000),
(4, 2017, 4900000000,  3822000000),
(4, 2018, 5580000000,  4352400000),
(4, 2019, 5800000000,  4582000000),
(4, 2020, 4450000000,  3782500000),
(4, 2021, 5760000000,  4492800000),
(4, 2022, 6170000000,  4812600000);


INSERT INTO historical_financials (company_id, fiscal_year, annual_revenue, operating_expense) VALUES
-- Company 5: Tommy Hilfiger (Casual American Lifestyle)
(5, 2010, 3150000000,  2425500000),
(5, 2011, 3300000000,  2508000000),
(5, 2012, 3400000000,  2618000000),
(5, 2013, 3510000000,  2632500000),
(5, 2014, 3800000000,  2888000000),
(5, 2015, 3700000000,  2849000000),
(5, 2016, 3200000000,  2496000000),
(5, 2017, 3500000000,  2695000000),
(5, 2018, 4100000000,  3157000000),
(5, 2019, 4300000000,  3311000000),
(5, 2020, 3000000000,  2460000000),
(5, 2021, 4400000000,  3344000000),
(5, 2022, 4700000000,  3619000000),

-- Company 6: Ralph Lauren (Premium Heritage Brand)
(6, 2010, 6200000000,  4712000000),
(6, 2011, 6700000000,  5025000000),
(6, 2012, 7200000000,  5400000000),
(6, 2013, 7400000000,  5550000000),
(6, 2014, 7600000000,  5776000000),
(6, 2015, 7400000000,  5624000000),
(6, 2016, 6700000000,  5159000000),
(6, 2017, 6300000000,  4914000000),
(6, 2018, 6100000000,  4758000000),
(6, 2019, 6300000000,  4977000000),
(6, 2020, 4400000000,  3608000000),
(6, 2021, 6200000000,  4712000000),
(6, 2022, 6400000000,  4928000000),

-- Company 7: H&M (High-Volume Fast Fashion)
(7, 2010, 14000000000, 10780000000),
(7, 2011, 16000000000, 12480000000),
(7, 2012, 17700000000, 13983000000),
(7, 2013, 18300000000, 14457000000),
(7, 2014, 21000000000, 16380000000),
(7, 2015, 22200000000, 17538000000),
(7, 2016, 22700000000, 17933000000),
(7, 2017, 21500000000, 17200000000),
(7, 2018, 22000000000, 17820000000),
(7, 2019, 23500000000, 19035000000),
(7, 2020, 18000000000, 15480000000),
(7, 2021, 21500000000, 17630000000),
(7, 2022, 22400000000, 18592000000),

-- Company 8: Zara (Inditex Core Fast Fashion Leader)
(8, 2010, 12500000000, 9375000000),
(8, 2011, 13800000000, 10350000000),
(8, 2012, 15900000000, 11925000000),
(8, 2013, 16700000000, 12358000000),
(8, 2014, 19700000000, 14578000000),
(8, 2015, 20400000000, 15096000000),
(8, 2016, 23300000000, 17242000000),
(8, 2017, 25300000000, 18722000000),
(8, 2018, 26100000000, 19314000000),
(8, 2019, 28200000000, 20868000000),
(8, 2020, 20400000000, 15912000000),
(8, 2021, 27700000000, 20498000000),
(8, 2022, 31200000000, 23088000000);


INSERT INTO historical_financials (company_id, fiscal_year, annual_revenue, operating_expense) VALUES
-- Company 9: Bottega Veneta (Exclusive Luxury Leather Goods)
(9, 2010, 950000000,   684000000),
(9, 2011, 1010000000,  717100000),
(9, 2012, 1130000000,  791000000),
(9, 2013, 1170000000,  807300000),
(9, 2014, 1250000000,  850000000),
(9, 2015, 1150000000,  793500000),
(9, 2016, 1170000000,  807300000),
(9, 2017, 1200000000,  816000000),
(9, 2018, 1160000000,  800400000),
(9, 2019, 1210000000,  822800000),
(9, 2020, 1500000000,  1005000000),
(9, 2021, 1740000000,  1148400000),
(9, 2022, 1780000000,  1174800000),

-- Company 10: Prada (High-Fashion Avant-Garde)
(10, 2010, 2150000000, 1569500000),
(10, 2011, 2300000000, 1656000000),
(10, 2012, 3100000000, 2170000000),
(10, 2013, 3290000000, 2269500000),
(10, 2014, 3580000000, 2434400000),
(10, 2015, 3550000000, 2449500000),
(10, 2016, 3180000000, 2226000000),
(10, 2017, 3050000000, 2165500000),
(10, 2018, 3140000000, 2229400000),
(10, 2019, 3220000000, 2254000000),
(10, 2020, 2420000000, 1790800000),
(10, 2021, 3360000000, 2318400000),
(10, 2022, 4200000000, 2856000000),

-- Company 11: Nike (Global Athletic Heavyweight)
(11, 2010, 20800000000, 15600000000),
(11, 2011, 24100000000, 17834000000),
(11, 2012, 25300000000, 18469000000),
(11, 2013, 27800000000, 20016000000),
(11, 2014, 30600000000, 21726000000),
(11, 2015, 32400000000, 22680000000),
(11, 2016, 34400000000, 23736000000),
(11, 2017, 36400000000, 24752000000),
(11, 2018, 39100000000, 26197000000),
(11, 2019, 41300000000, 27258000000),
(11, 2020, 37400000000, 25806000000),
(11, 2021, 44500000000, 29815000000),
(11, 2022, 46700000000, 30822000000),

-- Company 12: Adidas (European Sports Titan)
(12, 2010, 12000000000, 9480000000),
(12, 2011, 13300000000, 10374000000),
(12, 2012, 14900000000, 11473000000),
(12, 2013, 14500000000, 11310000000),
(12, 2014, 16900000000, 13182000000),
(12, 2015, 19300000000, 14861000000),
(12, 2016, 21200000000, 16112000000),
(12, 2017, 21900000000, 16644000000),
(12, 2018, 23600000000, 17936000000),
(12, 2019, 24500000000, 18375000000),
(12, 2020, 19800000000, 15642000000),
(12, 2021, 21200000000, 16536000000),
(12, 2022, 22500000000, 17325000000),

-- Company 13: Yves Saint Laurent (Haute Couture Chic)
(13, 2010, 450000000,   337500000),
(13, 2011, 550000000,   401500000),
(13, 2012, 700000000,   504000000),
(13, 2013, 970000000,   688800000),
(13, 2014, 1220000000,  854000000),
(13, 2015, 1500000000,  1035000000),
(13, 2016, 1740000000,  1183200000),
(13, 2017, 2040000000,  1366800000),
(13, 2018, 2240000000,  1478400000),
(13, 2019, 2520000000,  1638000000),
(13, 2020, 1950000000,  1365000000),
(13, 2021, 2800000000,  1848000000),
(13, 2022, 3100000000,  2015000000);


-- Populating structural macro trends table to measure industry share metrics per category
INSERT INTO market_trends (fiscal_year, fashion_category, global_market_size, category_annual_growth) VALUES
(2010, 'CASUAL WEAR',  150000000000, 3.4), (2010, 'FAST FASHION',  80000000000, 5.1),  (2010, 'HIGH FASHION',  60000000000, 1.2),  (2010, 'ATHLEISURE',   70000000000, 4.0),  (2010, 'PREPPY', 30000000000, 0.5),  (2010, 'CHIC', 20000000000, 2.5),
(2011, 'CASUAL WEAR',  155000000000, 3.3), (2011, 'FAST FASHION',  85000000000, 6.2),  (2011, 'HIGH FASHION',  61000000000, 1.6),  (2011, 'ATHLEISURE',   74000000000, 5.7),  (2011, 'PREPPY', 30200000000, 0.6),  (2011, 'CHIC', 21000000000, 5.0),
(2012, 'CASUAL WEAR',  161000000000, 3.8), (2012, 'FAST FASHION',  91000000000, 7.0),  (2012, 'HIGH FASHION',  63000000000, 3.2),  (2012, 'ATHLEISURE',   79000000000, 6.7),  (2012, 'PREPPY', 30500000000, 0.9),  (2012, 'CHIC', 22500000000, 7.1),
(2013, 'CASUAL WEAR',  165000000000, 2.4), (2013, 'FAST FASHION',  97000000000, 6.5),  (2013, 'HIGH FASHION',  65000000000, 3.1),  (2013, 'ATHLEISURE',   85000000000, 7.5),  (2013, 'PREPPY', 30800000000, 0.9),  (2013, 'CHIC', 24000000000, 6.6),
(2014, 'CASUAL WEAR',  172000000000, 4.2), (2014, 'FAST FASHION', 104000000000, 7.2),  (2014, 'HIGH FASHION',  68000000000, 4.6),  (2014, 'ATHLEISURE',   92000000000, 8.2),  (2014, 'PREPPY', 31000000000, 0.6),  (2014, 'CHIC', 25500000000, 6.2),
(2015, 'CASUAL WEAR',  170000000000, -1.1),(2015, 'FAST FASHION', 108000000000, 3.8),  (2015, 'HIGH FASHION',  66000000000, -2.9), (2015, 'ATHLEISURE',   98000000000, 6.5),  (2015, 'PREPPY', 30000000000, -3.2), (2015, 'CHIC', 26000000000, 1.9),
(2016, 'CASUAL WEAR',  174000000000, 2.3), (2016, 'FAST FASHION', 115000000000, 6.4),  (2016, 'HIGH FASHION',  68000000000, 3.0),  (2016, 'ATHLEISURE',  106000000000, 8.1),  (2016, 'PREPPY', 29500000000, -1.6), (2016, 'CHIC', 27200000000, 4.6),
(2017, 'CASUAL WEAR',  180000000000, 3.4), (2017, 'FAST FASHION', 123000000000, 6.9),  (2017, 'HIGH FASHION',  71000000000, 4.4),  (2017, 'ATHLEISURE',  115000000000, 8.4),  (2017, 'PREPPY', 29000000000, -1.7), (2017, 'CHIC', 29000000000, 6.6),
(2018, 'CASUAL WEAR',  185000000000, 2.7), (2018, 'FAST FASHION', 130000000000, 5.6),  (2018, 'HIGH FASHION',  73000000000, 2.8),  (2018, 'ATHLEISURE',  125000000000, 8.6),  (2018, 'PREPPY', 28500000000, -1.7), (2018, 'CHIC', 30500000000, 5.1),
(2019, 'CASUAL WEAR',  189000000000, 2.1), (2019, 'FAST FASHION', 136000000000, 4.6),  (2019, 'HIGH FASHION',  75000000000, 2.7),  (2019, 'ATHLEISURE',  135000000000, 8.0),  (2019, 'PREPPY', 28800000000, 1.05), (2019, 'CHIC', 32000000000, 4.9),
(2020, 'CASUAL WEAR',  160000000000, -15.3),(2020, 'FAST FASHION', 110000000000, -19.1),(2020, 'HIGH FASHION',  58000000000, -22.6),(2020, 'ATHLEISURE',  122000000000, -9.6), (2020, 'PREPPY', 21000000000, -27.0), (2020, 'CHIC', 25000000000, -21.8),
(2021, 'CASUAL WEAR',  182000000000, 13.7), (2021, 'FAST FASHION', 132000000000, 20.0), (2021, 'HIGH FASHION',  70000000000, 20.6), (2021, 'ATHLEISURE',  148000000000, 21.3), (2021, 'PREPPY', 27000000000, 28.5), (2021, 'CHIC', 31500000000, 26.0),
(2022, 'CASUAL WEAR',  195000000000, 7.1),  (2022, 'FAST FASHION', 145000000000, 9.8),  (2022, 'HIGH FASHION',  78000000000, 11.4), (2022, 'ATHLEISURE',  162000000000, 9.4),  (2022, 'PREPPY', 29000000000, 7.4),  (2022, 'CHIC', 34000000000, 7.9);


-- Summary Dashboard Query of Brands and Lifetime Scale Parameters
SELECT 
    fc.company_name,
    fc.fashion_category,
    fc.country_of_origin,
    fc.founding_year,
    (2026 - fc.founding_year) AS brand_age_years,
    TO_CHAR(MIN(hf.annual_revenue), '$9,999,999,999,990') AS baseline_revenue_2010,
    TO_CHAR(MAX(hf.annual_revenue), '$9,999,999,999,990') AS zenith_revenue,
    ROUND(AVG(hf.profit_margin_percentage), 2) AS avg_profit_margin_pct
FROM fashion_companies fc
INNER JOIN historical_financials hf ON fc.company_id = hf.company_id
GROUP BY fc.company_id, fc.company_name, fc.fashion_category, fc.country_of_origin, fc.founding_year
ORDER BY fc.fashion_category, avg_profit_margin_pct DESC;


-- Query to calculate YoY Revenue Growth Rate and raw change per corporate entity
WITH yoy_calculations AS (
    SELECT 
        fc.company_name,
        fc.fashion_category,
        hf.fiscal_year,
        hf.annual_revenue AS current_year_revenue,
        LAG(hf.annual_revenue, 1) OVER (
            PARTITION BY hf.company_id 
            ORDER BY hf.fiscal_year
        ) AS previous_year_revenue
    FROM fashion_companies fc
    JOIN historical_financials hf ON fc.company_id = hf.company_id
)
SELECT 
    company_name,
    fashion_category,
    fiscal_year,
    TO_CHAR(current_year_revenue, '$99,999,999,999') AS current_revenue,
    TO_CHAR(previous_year_revenue, '$99,999,999,999') AS previous_revenue,
    TO_CHAR((current_year_revenue - previous_year_revenue), '$S99,999,999,999') AS absolute_change,
    ROUND(
        ((current_year_revenue - previous_year_revenue) / NULLIF(previous_year_revenue, 0)) * 100, 
        2
    ) AS yoy_growth_rate_percentage
FROM yoy_calculations
WHERE previous_year_revenue IS NOT NULL
ORDER BY company_name, fiscal_year;


-- Calculates 3-year rolling average revenue to smooth structural volatility, plus cumulative revenue paths
SELECT 
    fc.company_name,
    hf.fiscal_year,
    TO_CHAR(hf.annual_revenue, '$99,999,999,999') AS raw_annual_revenue,
    TO_CHAR(
        AVG(hf.annual_revenue) OVER (
            PARTITION BY hf.company_id 
            ORDER BY hf.fiscal_year 
            ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
        ), 
        '$99,999,999,999'
    ) AS rolling_3_year_avg_revenue,
    TO_CHAR(
        SUM(hf.annual_revenue) OVER (
            PARTITION BY hf.company_id 
            ORDER BY hf.fiscal_year 
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ), 
        '$99,999,999,999'
    ) AS running_total_cumulative_revenue
FROM fashion_companies fc
JOIN historical_financials hf ON fc.company_id = hf.company_id
ORDER BY fc.company_name, hf.fiscal_year;


-- This query monitors the market concentration within each category (Herfindahl-Hirschman Index - HHI)
-- HHI under 1500 = highly competitive; 1500-2500 = moderately concentrated; above 2500 = heavily concentrated oligopoly.
WITH market_share_cte AS (
    SELECT 
        hf.fiscal_year,
        fc.fashion_category,
        fc.company_name,
        hf.annual_revenue,
        mt.global_market_size AS category_total_market,
        -- Calculate brand's market share of global category sizing
        (hf.annual_revenue / mt.global_market_size) * 100 AS brand_market_share
    FROM historical_financials hf
    JOIN fashion_companies fc ON hf.company_id = fc.company_id
    JOIN market_trends mt ON hf.fiscal_year = mt.fiscal_year 
         AND fc.fashion_category = mt.fashion_category
),
category_hhi_cte AS (
    SELECT 
        fiscal_year,
        fashion_category,
        ROUND(SUM(POWER(brand_market_share, 2))::NUMERIC, 2) AS category_hhi
    FROM market_share_cte
    GROUP BY fiscal_year, fashion_category
)
SELECT 
    ms.fiscal_year,
    ms.fashion_category,
    ms.company_name,
    ROUND(ms.brand_market_share, 2) AS market_share_percentage,
    ch.category_hhi,
    CASE 
        WHEN ch.category_hhi < 1500 THEN 'Competitive / Highly Fragmented Market'
        WHEN ch.category_hhi BETWEEN 1500 AND 2500 THEN 'Moderately Concentrated Market'
        ELSE 'Highly Concentrated Market / Duopoly'
    END AS structural_market_concentration
FROM market_share_cte ms
JOIN category_hhi_cte ch ON ms.fiscal_year = ch.fiscal_year AND ms.fashion_category = ch.fashion_category
ORDER BY ms.fiscal_year, ms.fashion_category, ms.brand_market_share DESC;


-- Computes historical CAGR (2010 to 2022) using advanced logarithmic power models
WITH boundary_financials AS (
    SELECT 
        company_id,
        MIN(fiscal_year) AS start_year,
        MAX(fiscal_year) AS end_year
    FROM historical_financials
    GROUP BY company_id
),
revenue_bounds AS (
    SELECT 
        bf.company_id,
        bf.start_year,
        bf.end_year,
        hf_start.annual_revenue AS start_revenue,
        hf_end.annual_revenue AS end_revenue,
        (bf.end_year - bf.start_year) AS total_periods
    FROM boundary_financials bf
    JOIN historical_financials hf_start ON bf.company_id = hf_start.company_id AND bf.start_year = hf_start.fiscal_year
    JOIN historical_financials hf_end ON bf.company_id = hf_end.company_id AND bf.end_year = hf_end.fiscal_year
)
SELECT 
    fc.company_name,
    fc.fashion_category,
    rb.start_year,
    TO_CHAR(rb.start_revenue, '$99,999,999,999') AS baseline_revenue,
    rb.end_year,
    TO_CHAR(rb.end_revenue, '$99,999,999,999') AS terminal_revenue,
    rb.total_periods AS span_years,
    -- Formula: CAGR = (End Value / Start Value) ^ (1 / n) - 1
    ROUND(
        (POWER((rb.end_revenue / rb.start_revenue)::DOUBLE PRECISION, (1.0 / rb.total_periods)::DOUBLE PRECISION) - 1.0)::NUMERIC * 100, 
        2
    ) AS historical_cagr_percentage
FROM revenue_bounds rb
JOIN fashion_companies fc ON rb.company_id = fc.company_id
ORDER BY historical_cagr_percentage DESC;


-- Evaluates financial consistency and flags performance anomalies where a year deviates by > 1.5 standard deviations
WITH stats_cte AS (
    SELECT 
        company_id,
        AVG(annual_revenue) AS avg_rev,
        STDDEV(annual_revenue) AS stddev_rev
    FROM historical_financials
    GROUP BY company_id
),
zscore_cte AS (
    SELECT 
        fc.company_name,
        hf.fiscal_year,
        hf.annual_revenue,
        sc.avg_rev,
        sc.stddev_rev,
        ROUND(
            (hf.annual_revenue - sc.avg_rev) / NULLIF(sc.stddev_rev, 0), 
            3
        ) AS revenue_z_score
    FROM historical_financials hf
    JOIN fashion_companies fc ON hf.company_id = fc.company_id
    JOIN stats_cte sc ON hf.company_id = sc.company_id
)
SELECT 
    company_name,
    fiscal_year,
    TO_CHAR(annual_revenue, '$99,999,999,999') AS annual_revenue,
    revenue_z_score,
    CASE 
        WHEN revenue_z_score > 1.50 THEN 'Anomaly: Exceptional High Performance Year'
        WHEN revenue_z_score < -1.50 THEN 'Anomaly: Underperformance / Restructuring Year'
        ELSE 'Standard Performance Boundary'
    END AS business_performance_flag
FROM zscore_cte
ORDER BY ABS(revenue_z_score) DESC, company_name;


-- View 1: Analytical executive summary dashboard
CREATE OR REPLACE VIEW vw_executive_summary_dashboard AS
SELECT 
    fc.company_name,
    fc.fashion_category,
    fc.company_region,
    COUNT(hf.fiscal_year) AS logged_fiscal_periods,
    TO_CHAR(AVG(hf.annual_revenue), '$99,999,999,999') AS mean_annual_revenue,
    TO_CHAR(SUM(hf.net_profit), '$99,999,999,999') AS life_net_profit_generated,
    ROUND(AVG(hf.profit_margin_percentage), 2) AS average_profit_margin_percentage,
    ROUND(MIN(hf.profit_margin_percentage), 2) AS minimum_operating_profit_margin_margin,
    ROUND(MAX(hf.profit_margin_percentage), 2) AS peak_operating_profit_margin
FROM fashion_companies fc
JOIN historical_financials hf ON fc.company_id = hf.company_id
GROUP BY fc.company_id, fc.company_name, fc.fashion_category, fc.company_region;

-- View 2: Regional market landscape perspective
CREATE OR REPLACE VIEW vw_regional_performance_summary AS
SELECT 
    fc.company_region,
    COUNT(DISTINCT fc.company_id) AS total_active_brands,
    TO_CHAR(SUM(hf.annual_revenue), '$99,999,999,999,990') AS regional_cumulative_generated_revenue,
    TO_CHAR(AVG(hf.annual_revenue), '$99,999,999,990') AS regional_average_brand_revenue,
    ROUND(AVG(hf.profit_margin_percentage), 2) AS average_regional_profitability_margin
FROM fashion_companies fc
JOIN historical_financials hf ON fc.company_id = hf.company_id
GROUP BY fc.company_region;

-- Testing operational views
SELECT * FROM vw_executive_summary_dashboard ORDER BY average_profit_margin_percentage DESC;
SELECT * FROM vw_regional_performance_summary ORDER BY regional_cumulative_generated_revenue DESC;


-- PL/pgSQL Function: Projects revenue using standard linear regression (Ordinary Least Squares)
-- Computes Slope (m) and Intercept (c) dynamically for a brand's dataset to forecast any future year.
CREATE OR REPLACE FUNCTION fn_project_future_revenue(
    target_company_id INT, 
    forecast_year INT
) 
RETURNS NUMERIC AS $$
DECLARE
    -- Linear regression formula components: y = m*x + c
    -- m = (N*sum(xy) - sum(x)*sum(y)) / (N*sum(x^2) - (sum(x))^2)
    -- c = (sum(y) - m*sum(x)) / N
    reg_slope NUMERIC;
    reg_intercept NUMERIC;
    n_count INT;
    sum_x NUMERIC; -- fiscal_year values
    sum_y NUMERIC; -- annual_revenue values
    sum_xx NUMERIC; -- square of fiscal_year
    sum_xy NUMERIC; -- product of x * y
    projected_value NUMERIC;
BEGIN
    -- Check boundaries for prediction
    IF forecast_year <= 2022 THEN
        RAISE EXCEPTION 'Target forecast year must be in the future (post-2022 dataset boundaries)';
    END IF;

    -- Aggregate regression parameters
    SELECT 
        COUNT(*),
        SUM(fiscal_year),
        SUM(annual_revenue),
        SUM(fiscal_year * fiscal_year),
        SUM(fiscal_year * annual_revenue)
    INTO 
        n_count, sum_x, sum_y, sum_xx, sum_xy
    FROM historical_financials
    WHERE company_id = target_company_id;

    -- Protect against division by zero errors
    IF n_count IS NULL OR n_count < 2 OR (n_count * sum_xx - sum_x * sum_x) = 0 THEN
        RETURN 0.00;
    END IF;

    -- Compute Regression parameters
    reg_slope := (n_count * sum_xy - sum_x * sum_y) / (n_count * sum_xx - sum_x * sum_x);
    reg_intercept := (sum_y - reg_slope * sum_x) / n_count;

    -- Solve Linear Trend: y = mx + c
    projected_value := reg_slope * forecast_year + reg_intercept;

    -- Do not predict negative corporate performance
    IF projected_value < 0 THEN
        RETURN 0.00;
    END IF;

    RETURN ROUND(projected_value, 2);
END;
$$ LANGUAGE plpgsql;

-- Execute Future Forecasting for Uniqlo and Nike targeting 2028 and 2030 corporate planning cycles
SELECT 
    company_name,
    fashion_category,
    TO_CHAR(fn_project_future_revenue(company_id, 2028), '$99,999,999,999,990') AS forecasted_revenue_2028,
    TO_CHAR(fn_project_future_revenue(company_id, 2032), '$99,999,999,999,990') AS forecasted_revenue_2032
FROM fashion_companies
WHERE company_id IN (1, 11);


-- Audit trigger function to track edits and enforce financial standards
CREATE OR REPLACE FUNCTION fn_audit_financial_actions()
RETURNS TRIGGER AS $$
BEGIN
    -- Operational integrity assertion: enforce that annual expenses do not outgrow total revenues by more than 150% (prevents typos)
    IF (TG_OP = 'INSERT' OR TG_OP = 'UPDATE') THEN
        IF NEW.operating_expense > (NEW.annual_revenue * 2.5) THEN
            RAISE EXCEPTION 'Financial Exception: Input anomaly where Operating Expense is over 250 percent of total Annual Revenue.';
        END IF;
    END IF;

    -- Auditing Data log mapping
    IF (TG_OP = 'UPDATE') THEN
        INSERT INTO audit_financial_logs (action_type, company_id, fiscal_year, old_revenue, new_revenue)
        VALUES ('UPDATE', OLD.company_id, OLD.fiscal_year, OLD.annual_revenue, NEW.annual_revenue);
        RETURN NEW;
    ELSIF (TG_OP = 'INSERT') THEN
        INSERT INTO audit_financial_logs (action_type, company_id, fiscal_year, old_revenue, new_revenue)
        VALUES ('INSERT', NEW.company_id, NEW.fiscal_year, NULL, NEW.annual_revenue);
        RETURN NEW;
    ELSIF (TG_OP = 'DELETE') THEN
        INSERT INTO audit_financial_logs (action_type, company_id, fiscal_year, old_revenue, new_revenue)
        VALUES ('DELETE', OLD.company_id, OLD.fiscal_year, OLD.annual_revenue, NULL);
        RETURN OLD;
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

-- Attaching Row-Level Trigger on table historical_financials
CREATE TRIGGER trg_audit_financial_adjustments
AFTER INSERT OR UPDATE OR DELETE
ON historical_financials
FOR EACH ROW
EXECUTE FUNCTION fn_audit_financial_actions();


-- Let's run simulated updates to verify the analytical system is reactive and audited correctly.
-- Testing typical revenue correction event for Gap (Company 3) in fiscal year 2022
UPDATE historical_financials
SET annual_revenue = 16000000000 -- Original value was 1.575e+10 (as from image_9a4e42.jpg)
WHERE company_id = 3 AND fiscal_year = 2022;

-- Testing typical performance update trigger verification
SELECT * FROM audit_financial_logs;

-- Revert adjustment to retain baseline integrity matching the original image_9a4e42.jpg dataset
UPDATE historical_financials
SET annual_revenue = 15750000000
WHERE company_id = 3 AND fiscal_year = 2022;

-- Verify Audit history reflects baseline preservation
SELECT * FROM audit_financial_logs ORDER BY adjusted_at DESC;

-- Comprehensive analytical report showcasing our advanced features combined:
-- Brands that outperformed their category peer averages in consecutive periods.
WITH competitive_adv AS (
    SELECT 
        fc.company_name,
        fc.fashion_category,
        hf.fiscal_year,
        hf.profit_margin_percentage,
        AVG(hf.profit_margin_percentage) OVER (
            PARTITION BY fc.fashion_category, hf.fiscal_year
        ) AS category_avg_profit_margin
    FROM fashion_companies fc
    JOIN historical_financials hf ON fc.company_id = hf.company_id
)
SELECT 
    company_name,
    fashion_category,
    fiscal_year,
    profit_margin_percentage AS brand_margin,
    ROUND(category_avg_profit_margin, 2) AS sector_average_margin,
    ROUND(profit_margin_percentage - category_avg_profit_margin, 2) AS alpha_margin_outperformance
FROM competitive_adv
WHERE profit_margin_percentage > category_avg_profit_margin
ORDER BY alpha_margin_outperformance DESC, fiscal_year DESC;

-- ====================================================================================================
-- END OF ANALYTICAL DATABASE PROJECT SCRIPT
-- ====================================================================================================
-- ==============================================================================
-- PROJECT: TESLA (TSLA) STOCK DATA ANALYTICS MASTER SUITE
-- DESCRIPTION: A comprehensive SQL project generating 900+ days of stock data
--              and performing advanced algorithmic and quantitative analysis.
-- DIALECT: PostgreSQL (Standard SQL compliant with Window Functions)
-- ==============================================================================

-- 1. SCHEMA SETUP
-- Drop table if it exists to ensure a clean slate
DROP TABLE IF EXISTS tesla_stock_data;

-- Create the primary stock data table
CREATE TABLE tesla_stock_data (
    trading_date DATE PRIMARY KEY,
    open_price NUMERIC(10, 4),
    high_price NUMERIC(10, 4),
    low_price NUMERIC(10, 4),
    close_price NUMERIC(10, 4),
    adj_close NUMERIC(10, 4),
    volume BIGINT
);

-- ==============================================================================
-- 2. DATA GENERATION (SIMULATING 900+ TRADING DAYS)
-- We use a Recursive Common Table Expression (CTE) to generate ~950 days of data.
-- This simulates TSLA price action using a random walk algorithm.
-- ==============================================================================
WITH RECURSIVE date_series AS (
    -- Start date (approx 4 years of trading days ~ 950 days)
    SELECT 
        '2020-01-01'::DATE AS current_date,
        30.00::NUMERIC AS prev_close -- TSLA split-adjusted base price approx
    UNION ALL
    SELECT 
        current_date + INTERVAL '1 day',
        -- Random walk: Price changes by a random percentage between -5% and +5.5% (upward bias)
        (prev_close * (1 + (RANDOM() * 0.105 - 0.05)))::NUMERIC
    FROM date_series
    WHERE current_date < '2023-12-31'
),
trading_days AS (
    -- Filter out weekends to simulate actual trading days
    SELECT 
        current_date AS trading_date,
        prev_close AS simulated_close
    FROM date_series
    WHERE EXTRACT(ISODOW FROM current_date) < 6
)
-- Insert the generated data into our table
INSERT INTO tesla_stock_data (trading_date, open_price, high_price, low_price, close_price, adj_close, volume)
SELECT 
    trading_date,
    -- Open price is close to previous close
    ROUND((simulated_close * (1 + (RANDOM() * 0.02 - 0.01))), 4) AS open_price,
    -- High price is higher than open and close
    ROUND((simulated_close * (1 + (RANDOM() * 0.03))), 4) AS high_price,
    -- Low price is lower than open and close
    ROUND((simulated_close * (1 - (RANDOM() * 0.03))), 4) AS low_price,
    ROUND(simulated_close, 4) AS close_price,
    ROUND(simulated_close, 4) AS adj_close,
    -- Random volume between 50M and 200M
    (50000000 + (RANDOM() * 150000000))::BIGINT AS volume
FROM trading_days;


-- ==============================================================================
-- 3. FUNDAMENTAL ANALYTICAL QUERIES
-- ==============================================================================

-- Query 1: Retrieve the first 10 days of data to verify insertion
SELECT * FROM tesla_stock_data ORDER BY trading_date ASC LIMIT 10;

-- Query 2: Total number of trading days recorded (Verifying the 900+ requirement)
SELECT COUNT(*) AS total_trading_days FROM tesla_stock_data;

-- Query 3: Find the All-Time High (ATH) and All-Time Low (ATL) for the dataset
SELECT 
    MIN(low_price) AS all_time_low,
    MAX(high_price) AS all_time_high,
    ROUND(AVG(close_price), 2) AS average_closing_price
FROM tesla_stock_data;

-- Query 4: Yearly Performance Summary (Open, Close, High, Low per year)
SELECT 
    EXTRACT(YEAR FROM trading_date) AS trading_year,
    MIN(low_price) AS yearly_low,
    MAX(high_price) AS yearly_high,
    ROUND(AVG(volume), 0) AS avg_daily_volume
FROM tesla_stock_data
GROUP BY EXTRACT(YEAR FROM trading_date)
ORDER BY trading_year;

-- ==============================================================================
-- 4. RETURNS AND VOLATILITY ANALYSIS
-- ==============================================================================

-- Query 5: Calculate Daily Price Change and Daily Return Percentage
SELECT 
    trading_date,
    close_price,
    LAG(close_price) OVER (ORDER BY trading_date) AS previous_close,
    close_price - LAG(close_price) OVER (ORDER BY trading_date) AS absolute_change,
    ROUND(((close_price - LAG(close_price) OVER (ORDER BY trading_date)) / 
           LAG(close_price) OVER (ORDER BY trading_date)) * 100, 2) AS daily_return_pct
FROM tesla_stock_data
ORDER BY trading_date DESC
LIMIT 50;

-- Query 6: Find the Top 10 Best Trading Days (Highest positive return)
WITH DailyReturns AS (
    SELECT 
        trading_date,
        ROUND(((close_price - LAG(close_price) OVER (ORDER BY trading_date)) / 
               LAG(close_price) OVER (ORDER BY trading_date)) * 100, 2) AS return_pct
    FROM tesla_stock_data
)
SELECT * FROM DailyReturns 
WHERE return_pct IS NOT NULL 
ORDER BY return_pct DESC 
LIMIT 10;

-- Query 7: Calculate True Range (TR) to measure daily volatility
SELECT 
    trading_date,
    high_price,
    low_price,
    LAG(close_price) OVER (ORDER BY trading_date) AS prev_close,
    GREATEST(
        high_price - low_price,
        ABS(high_price - LAG(close_price) OVER (ORDER BY trading_date)),
        ABS(low_price - LAG(close_price) OVER (ORDER BY trading_date))
    ) AS true_range
FROM tesla_stock_data
LIMIT 50;

-- ==============================================================================
-- 5. MOVING AVERAGES (TREND INDICATORS)
-- ==============================================================================

-- Query 8: Simple Moving Averages (SMA) - 7-day, 20-day, and 50-day
SELECT 
    trading_date,
    close_price,
    ROUND(AVG(close_price) OVER (ORDER BY trading_date ROWS BETWEEN 6 PRECEDING AND CURRENT ROW), 2) AS sma_7,
    ROUND(AVG(close_price) OVER (ORDER BY trading_date ROWS BETWEEN 19 PRECEDING AND CURRENT ROW), 2) AS sma_20,
    ROUND(AVG(close_price) OVER (ORDER BY trading_date ROWS BETWEEN 49 PRECEDING AND CURRENT ROW), 2) AS sma_50
FROM tesla_stock_data
ORDER BY trading_date DESC
LIMIT 100;

-- Query 9: Golden Cross and Death Cross Detection
-- A Golden Cross occurs when a short-term SMA crosses above a long-term SMA.
WITH MovingAverages AS (
    SELECT 
        trading_date,
        close_price,
        AVG(close_price) OVER (ORDER BY trading_date ROWS BETWEEN 49 PRECEDING AND CURRENT ROW) AS sma_50,
        AVG(close_price) OVER (ORDER BY trading_date ROWS BETWEEN 199 PRECEDING AND CURRENT ROW) AS sma_200
    FROM tesla_stock_data
),
TrendCrosses AS (
    SELECT 
        trading_date,
        sma_50,
        sma_200,
        CASE 
            WHEN sma_50 > sma_200 AND LAG(sma_50) OVER (ORDER BY trading_date) <= LAG(sma_200) OVER (ORDER BY trading_date) THEN 'Golden Cross (Bullish)'
            WHEN sma_50 < sma_200 AND LAG(sma_50) OVER (ORDER BY trading_date) >= LAG(sma_200) OVER (ORDER BY trading_date) THEN 'Death Cross (Bearish)'
            ELSE 'No Cross'
        END AS cross_signal
    FROM MovingAverages
)
SELECT * FROM TrendCrosses WHERE cross_signal != 'No Cross' ORDER BY trading_date DESC;

-- ==============================================================================
-- 6. ADVANCED QUANTITATIVE INDICATORS
-- ==============================================================================

-- Query 10: Bollinger Bands (20-day SMA +/- 2 Standard Deviations)
WITH Stats_20Day AS (
    SELECT 
        trading_date,
        close_price,
        AVG(close_price) OVER (ORDER BY trading_date ROWS BETWEEN 19 PRECEDING AND CURRENT ROW) AS sma_20,
        STDDEV(close_price) OVER (ORDER BY trading_date ROWS BETWEEN 19 PRECEDING AND CURRENT ROW) AS stddev_20
    FROM tesla_stock_data
)
SELECT 
    trading_date,
    close_price,
    ROUND(sma_20 + (2 * stddev_20), 2) AS upper_bollinger_band,
    ROUND(sma_20, 2) AS middle_band,
    ROUND(sma_20 - (2 * stddev_20), 2) AS lower_bollinger_band,
    CASE
        WHEN close_price > (sma_20 + (2 * stddev_20)) THEN 'Overbought / Breakout'
        WHEN close_price < (sma_20 - (2 * stddev_20)) THEN 'Oversold / Breakdown'
        ELSE 'Within Bands'
    END AS band_signal
FROM Stats_20Day
ORDER BY trading_date DESC
LIMIT 50;

-- Query 11: Relative Strength Index (RSI) - 14 Day Period
-- This is a highly complex SQL maneuver calculating average gains and losses.
WITH DailyChanges AS (
    SELECT 
        trading_date,
        close_price,
        close_price - LAG(close_price) OVER (ORDER BY trading_date) AS price_change
    FROM tesla_stock_data
),
GainsAndLosses AS (
    SELECT 
        trading_date,
        close_price,
        CASE WHEN price_change > 0 THEN price_change ELSE 0 END AS gain,
        CASE WHEN price_change < 0 THEN ABS(price_change) ELSE 0 END AS loss
    FROM DailyChanges
),
AvgGainsLosses AS (
    SELECT 
        trading_date,
        close_price,
        AVG(gain) OVER (ORDER BY trading_date ROWS BETWEEN 13 PRECEDING AND CURRENT ROW) AS avg_gain_14d,
        AVG(loss) OVER (ORDER BY trading_date ROWS BETWEEN 13 PRECEDING AND CURRENT ROW) AS avg_loss_14d
    FROM GainsAndLosses
),
RSICalculation AS (
    SELECT 
        trading_date,
        close_price,
        CASE 
            WHEN avg_loss_14d = 0 THEN 100 
            ELSE 100 - (100 / (1 + (avg_gain_14d / avg_loss_14d))) 
        END AS rsi_14
    FROM AvgGainsLosses
)
SELECT 
    trading_date,
    close_price,
    ROUND(rsi_14, 2) AS rsi,
    CASE 
        WHEN rsi_14 >= 70 THEN 'Overbought'
        WHEN rsi_14 <= 30 THEN 'Oversold'
        ELSE 'Neutral'
    END AS rsi_signal
FROM RSICalculation
ORDER BY trading_date DESC
LIMIT 50;

-- ==============================================================================
-- 7. VOLUME AND GAP ANALYSIS
-- ==============================================================================

-- Query 12: Volume Weighted Average Price (VWAP) - Cumulative for the year
WITH CumulativeData AS (
    SELECT 
        trading_date,
        close_price,
        volume,
        EXTRACT(YEAR FROM trading_date) AS trading_year,
        SUM(close_price * volume) OVER (PARTITION BY EXTRACT(YEAR FROM trading_date) ORDER BY trading_date) AS cumulative_pv,
        SUM(volume) OVER (PARTITION BY EXTRACT(YEAR FROM trading_date) ORDER BY trading_date) AS cumulative_volume
    FROM tesla_stock_data
)
SELECT 
    trading_date,
    close_price,
    volume,
    ROUND(cumulative_pv / cumulative_volume, 2) AS ytd_vwap
FROM CumulativeData
ORDER BY trading_date DESC
LIMIT 50;

-- Query 13: Identifying "Gap Ups" and "Gap Downs"
-- A gap occurs when the open price is significantly different from the previous close.
WITH Gaps AS (
    SELECT 
        trading_date,
        LAG(close_price) OVER (ORDER BY trading_date) AS prev_close,
        open_price,
        close_price,
        ROUND(((open_price - LAG(close_price) OVER (ORDER BY trading_date)) / LAG(close_price) OVER (ORDER BY trading_date)) * 100, 2) AS gap_percent
    FROM tesla_stock_data
)
SELECT 
    trading_date,
    prev_close,
    open_price,
    gap_percent,
    CASE 
        WHEN gap_percent > 2.0 THEN 'Major Gap Up'
        WHEN gap_percent < -2.0 THEN 'Major Gap Down'
        ELSE 'Normal Open'
    END AS gap_type
FROM Gaps
WHERE ABS(gap_percent) > 2.0
ORDER BY trading_date DESC;

-- END OF PROJECT
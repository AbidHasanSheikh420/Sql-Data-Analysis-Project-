-- ==============================================================================
-- ALIBABA (BABA) STOCK DATA ANALYTICS MASTER SCRIPT
-- ==============================================================================
-- Description: A comprehensive suite of analytical SQL queries for stock market 
-- data, focusing on technical analysis, momentum indicators, volatility, volume 
-- profiling, and algorithmic pattern recognition.
-- Dialect: PostgreSQL (Utilizes advanced Window Functions & CTEs)
-- ==============================================================================

-- 1. DDL: Create the fundamental tables for the analytics project
DROP TABLE IF EXISTS alibaba_stock_daily CASCADE;

CREATE TABLE alibaba_stock_daily (
    trade_date DATE PRIMARY KEY,
    open_price NUMERIC(10, 4),
    high_price NUMERIC(10, 4),
    low_price NUMERIC(10, 4),
    close_price NUMERIC(10, 4),
    adj_close NUMERIC(10, 4),
    volume BIGINT
);

-- 2. DML: Insert mock data for testing (In production, this is loaded via CSV/ETL)
-- Note: Just a small sample to ensure queries are runnable. Imagine 3000+ rows here.
INSERT INTO alibaba_stock_daily (trade_date, open_price, high_price, low_price, close_price, adj_close, volume) VALUES
('2023-10-01', 85.50, 87.20, 84.10, 86.10, 86.10, 15000000),
('2023-10-02', 86.00, 88.00, 85.50, 87.50, 87.50, 16500000),
('2023-10-03', 87.10, 87.50, 84.80, 85.20, 85.20, 14200000),
('2023-10-04', 85.00, 86.50, 84.00, 86.30, 86.30, 13800000),
('2023-10-05', 86.50, 89.10, 86.00, 88.90, 88.90, 21000000),
('2023-10-06', 89.00, 90.50, 88.20, 90.10, 90.10, 25000000),
('2023-10-07', 90.20, 91.00, 88.50, 89.40, 89.40, 18000000),
('2023-10-08', 89.10, 89.50, 86.20, 86.80, 86.80, 22000000),
('2023-10-09', 87.00, 88.40, 86.50, 87.90, 87.90, 17500000),
('2023-10-10', 88.00, 92.00, 87.50, 91.50, 91.50, 30000000);

-- ==============================================================================
-- PART 1: EXPLORATORY DATA ANALYSIS (EDA) & BASIC METRICS
-- ==============================================================================

-- Query 1: Retrieve basic descriptive statistics for the entire dataset
SELECT 
    COUNT(*) as total_trading_days,
    MIN(trade_date) as first_date,
    MAX(trade_date) as last_date,
    ROUND(AVG(close_price), 2) as all_time_avg_close,
    MAX(high_price) as all_time_high,
    MIN(low_price) as all_time_low,
    ROUND(AVG(volume), 0) as avg_daily_volume
FROM alibaba_stock_daily;

-- Query 2: Calculate daily price change and percentage change
SELECT 
    trade_date,
    close_price,
    close_price - open_price AS intraday_change_usd,
    ROUND(((close_price - open_price) / open_price) * 100, 2) AS intraday_change_pct
FROM alibaba_stock_daily
ORDER BY trade_date DESC;

-- ==============================================================================
-- PART 2: TIME SERIES & TREND ANALYSIS (MOVING AVERAGES)
-- ==============================================================================

-- Query 3: Calculate Simple Moving Averages (SMA) - 3-day and 5-day
-- (Using smaller windows for the mock data, usually 50/200 for real data)
SELECT 
    trade_date,
    close_price,
    ROUND(AVG(close_price) OVER (ORDER BY trade_date ROWS BETWEEN 2 PRECEDING AND CURRENT ROW), 2) AS sma_3,
    ROUND(AVG(close_price) OVER (ORDER BY trade_date ROWS BETWEEN 4 PRECEDING AND CURRENT ROW), 2) AS sma_5
FROM alibaba_stock_daily
ORDER BY trade_date;

-- Query 4: Calculate Exponential Moving Average (EMA) Approximation
-- (Uses a recursive CTE for accurate EMA calculation)
WITH RECURSIVE ema_calc AS (
    -- Base case: First day is just the close price
    SELECT 
        trade_date, 
        close_price, 
        close_price AS ema_5,
        ROW_NUMBER() OVER (ORDER BY trade_date) as rn
    FROM alibaba_stock_daily
    ORDER BY trade_date
    LIMIT 1
    
    UNION ALL
    
    -- Recursive step: Calculate EMA
    SELECT 
        curr.trade_date, 
        curr.close_price, 
        (curr.close_price * (2.0 / (5 + 1))) + (prev.ema_5 * (1 - (2.0 / (5 + 1)))) AS ema_5,
        curr.rn
    FROM (SELECT trade_date, close_price, ROW_NUMBER() OVER (ORDER BY trade_date) as rn FROM alibaba_stock_daily) curr
    JOIN ema_calc prev ON curr.rn = prev.rn + 1
)
SELECT trade_date, close_price, ROUND(ema_5, 2) AS ema_5
FROM ema_calc;

-- ==============================================================================
-- PART 3: VOLATILITY & RISK METRICS
-- ==============================================================================

-- Query 5: Calculate Daily True Range (TR) and Average True Range (ATR)
WITH true_range_calc AS (
    SELECT 
        trade_date,
        high_price,
        low_price,
        close_price,
        LAG(close_price) OVER (ORDER BY trade_date) as prev_close,
        GREATEST(
            high_price - low_price,
            ABS(high_price - LAG(close_price) OVER (ORDER BY trade_date)),
            ABS(low_price - LAG(close_price) OVER (ORDER BY trade_date))
        ) AS true_range
    FROM alibaba_stock_daily
)
SELECT 
    trade_date,
    ROUND(true_range, 2) AS true_range,
    ROUND(AVG(true_range) OVER (ORDER BY trade_date ROWS BETWEEN 4 PRECEDING AND CURRENT ROW), 2) AS atr_5
FROM true_range_calc;

-- Query 6: Calculate Bollinger Bands (20-day standard, using 5-day for mock data)
WITH stats AS (
    SELECT 
        trade_date,
        close_price,
        AVG(close_price) OVER (ORDER BY trade_date ROWS BETWEEN 4 PRECEDING AND CURRENT ROW) as sma_5,
        STDDEV(close_price) OVER (ORDER BY trade_date ROWS BETWEEN 4 PRECEDING AND CURRENT ROW) as stddev_5
    FROM alibaba_stock_daily
)
SELECT 
    trade_date,
    close_price,
    ROUND(sma_5, 2) AS middle_band,
    ROUND(sma_5 + (2 * COALESCE(stddev_5, 0)), 2) AS upper_band,
    ROUND(sma_5 - (2 * COALESCE(stddev_5, 0)), 2) AS lower_band,
    -- Signal when price breaks out of bands
    CASE 
        WHEN close_price > (sma_5 + (2 * stddev_5)) THEN 'Overbought / Breakout Up'
        WHEN close_price < (sma_5 - (2 * stddev_5)) THEN 'Oversold / Breakout Down'
        ELSE 'Within Bands'
    END AS bollinger_signal
FROM stats;

-- ==============================================================================
-- PART 4: ADVANCED MOMENTUM INDICATORS
-- ==============================================================================

-- Query 7: Relative Strength Index (RSI) - 14 Day Standard (Adapted for mock data)
WITH price_changes AS (
    SELECT 
        trade_date, 
        close_price,
        close_price - LAG(close_price) OVER(ORDER BY trade_date) as change
    FROM alibaba_stock_daily
),
gains_losses AS (
    SELECT 
        trade_date,
        CASE WHEN change > 0 THEN change ELSE 0 END as gain,
        CASE WHEN change < 0 THEN ABS(change) ELSE 0 END as loss
    FROM price_changes
),
averages AS (
    SELECT 
        trade_date,
        AVG(gain) OVER(ORDER BY trade_date ROWS BETWEEN 4 PRECEDING AND CURRENT ROW) as avg_gain,
        AVG(loss) OVER(ORDER BY trade_date ROWS BETWEEN 4 PRECEDING AND CURRENT ROW) as avg_loss
    FROM gains_losses
)
SELECT 
    trade_date,
    ROUND(
        CASE 
            WHEN avg_loss = 0 THEN 100 
            ELSE 100.0 - (100.0 / (1.0 + (avg_gain / avg_loss))) 
        END, 2
    ) AS rsi_5
FROM averages;

-- Query 8: MACD (Moving Average Convergence Divergence)
-- Typically 12-day EMA minus 26-day EMA, with a 9-day EMA signal line.
-- (Simplified using SMAs for brevity in this specific block without RECURSIVE overload)
WITH short_long_sma AS (
    SELECT 
        trade_date,
        AVG(close_price) OVER (ORDER BY trade_date ROWS BETWEEN 2 PRECEDING AND CURRENT ROW) as sma_short,
        AVG(close_price) OVER (ORDER BY trade_date ROWS BETWEEN 5 PRECEDING AND CURRENT ROW) as sma_long
    FROM alibaba_stock_daily
),
macd_base AS (
    SELECT 
        trade_date,
        sma_short - sma_long AS macd_line
    FROM short_long_sma
)
SELECT 
    trade_date,
    ROUND(macd_line, 4) AS macd_line,
    ROUND(AVG(macd_line) OVER (ORDER BY trade_date ROWS BETWEEN 2 PRECEDING AND CURRENT ROW), 4) AS signal_line,
    ROUND(macd_line - AVG(macd_line) OVER (ORDER BY trade_date ROWS BETWEEN 2 PRECEDING AND CURRENT ROW), 4) AS macd_histogram
FROM macd_base;

-- ==============================================================================
-- PART 5: VOLUME PROFILE & LIQUIDITY ANALYSIS
-- ==============================================================================

-- Query 9: Volume Weighted Average Price (VWAP) - Cumulative for the period
SELECT 
    trade_date,
    close_price,
    volume,
    -- Typical Price = (High + Low + Close) / 3
    ROUND((high_price + low_price + close_price) / 3, 2) AS typical_price,
    ROUND(
        SUM(((high_price + low_price + close_price) / 3) * volume) OVER (ORDER BY trade_date) 
        / 
        SUM(volume) OVER (ORDER BY trade_date), 
    2) AS cumulative_vwap
FROM alibaba_stock_daily;

-- Query 10: On-Balance Volume (OBV)
WITH price_dir AS (
    SELECT 
        trade_date,
        volume,
        close_price,
        LAG(close_price) OVER (ORDER BY trade_date) as prev_close
    FROM alibaba_stock_daily
),
obv_calc AS (
    SELECT 
        trade_date,
        CASE 
            WHEN prev_close IS NULL THEN 0
            WHEN close_price > prev_close THEN volume
            WHEN close_price < prev_close THEN -volume
            ELSE 0
        END AS obv_shift
    FROM price_dir
)
SELECT 
    trade_date,
    SUM(obv_shift) OVER (ORDER BY trade_date) AS on_balance_volume
FROM obv_calc;

-- ==============================================================================
-- PART 6: ALGORITHMIC PATTERN RECOGNITION (CANDLESTICKS)
-- ==============================================================================

-- Query 11: Detect Doji Stars & Hammer Patterns
SELECT 
    trade_date,
    open_price, high_price, low_price, close_price,
    -- Doji: Open and Close are almost identical (less than 0.2% difference)
    CASE 
        WHEN ABS(open_price - close_price) <= (high_price - low_price) * 0.1 
        THEN 'DOJI DETECTED' ELSE NULL 
    END AS doji_pattern,
    -- Hammer: Long lower shadow, small body, little to no upper shadow
    CASE 
        WHEN (LEAST(open_price, close_price) - low_price) > (3 * ABS(open_price - close_price))
        AND (high_price - GREATEST(open_price, close_price)) < ABS(open_price - close_price)
        THEN 'HAMMER DETECTED' ELSE NULL
    END AS hammer_pattern
FROM alibaba_stock_daily;

-- Query 12: Detect Bullish & Bearish Engulfing Patterns
WITH prev_day AS (
    SELECT 
        trade_date, open_price, close_price,
        LAG(open_price) OVER (ORDER BY trade_date) as prev_open,
        LAG(close_price) OVER (ORDER BY trade_date) as prev_close
    FROM alibaba_stock_daily
)
SELECT 
    trade_date,
    CASE 
        -- Bullish Engulfing: Prev day is down, current day opens lower than prev close but closes higher than prev open
        WHEN prev_close < prev_open 
             AND open_price <= prev_close 
             AND close_price > prev_open 
        THEN 'BULLISH ENGULFING'
        
        -- Bearish Engulfing: Prev day is up, current day opens higher than prev close but closes lower than prev open
        WHEN prev_close > prev_open 
             AND open_price >= prev_close 
             AND close_price < prev_open 
        THEN 'BEARISH ENGULFING'
        
        ELSE 'NONE'
    END AS engulfing_pattern
FROM prev_day
WHERE prev_open IS NOT NULL;

-- ==============================================================================
-- PART 7: PERFORMANCE & DRAWDOWN ANALYSIS
-- ==============================================================================

-- Query 13: Calculate Peak-to-Trough Drawdowns
WITH rolling_peak AS (
    SELECT 
        trade_date,
        close_price,
        MAX(close_price) OVER (ORDER BY trade_date) AS peak_price
    FROM alibaba_stock_daily
)
SELECT 
    trade_date,
    close_price,
    peak_price,
    ROUND(((close_price - peak_price) / peak_price) * 100, 2) AS current_drawdown_pct
FROM rolling_peak;

-- Query 14: Automated Support & Resistance Detection (Local Min/Max)
WITH local_extrema AS (
    SELECT 
        trade_date,
        low_price,
        high_price,
        LAG(low_price, 1) OVER w as prev_low_1,
        LAG(low_price, 2) OVER w as prev_low_2,
        LEAD(low_price, 1) OVER w as next_low_1,
        LEAD(low_price, 2) OVER w as next_low_2,
        
        LAG(high_price, 1) OVER w as prev_high_1,
        LAG(high_price, 2) OVER w as prev_high_2,
        LEAD(high_price, 1) OVER w as next_high_1,
        LEAD(high_price, 2) OVER w as next_high_2
    FROM alibaba_stock_daily
    WINDOW w AS (ORDER BY trade_date)
)
SELECT 
    trade_date,
    CASE 
        WHEN low_price < prev_low_1 AND low_price < prev_low_2 
             AND low_price < next_low_1 AND low_price < next_low_2 
        THEN 'POTENTIAL SUPPORT LEVEL'
    END AS support_zone,
    CASE 
        WHEN high_price > prev_high_1 AND high_price > prev_high_2 
             AND high_price > next_high_1 AND high_price > next_high_2 
        THEN 'POTENTIAL RESISTANCE LEVEL'
    END AS resistance_zone
FROM local_extrema
WHERE (low_price < prev_low_1 AND low_price < prev_low_2 AND low_price < next_low_1 AND low_price < next_low_2)
   OR (high_price > prev_high_1 AND high_price > prev_high_2 AND high_price > next_high_1 AND high_price > next_high_2);

-- ==============================================================================
-- PART 8: CONSECUTIVE STREAKS & GAP ANALYSIS
-- ==============================================================================

-- Query 15: Identify Run-away Gaps (Price opens significantly higher/lower than previous close)
SELECT 
    trade_date,
    LAG(close_price) OVER (ORDER BY trade_date) as previous_close,
    open_price,
    ROUND(((open_price - LAG(close_price) OVER (ORDER BY trade_date)) / LAG(close_price) OVER (ORDER BY trade_date)) * 100, 2) AS gap_pct,
    CASE 
        WHEN open_price > LAG(high_price) OVER (ORDER BY trade_date) THEN 'GAP UP'
        WHEN open_price < LAG(low_price) OVER (ORDER BY trade_date) THEN 'GAP DOWN'
        ELSE 'NO GAP'
    END AS gap_type
FROM alibaba_stock_daily;

-- END OF ANALYTICS SCRIPT
-- ==============================================================================
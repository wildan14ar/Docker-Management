-- ==================================================
-- INIT SQL FOR CITUS COORDINATOR - MARKET SERVICE
-- Market Data and Analysis Database
-- ==================================================

-- Create extension for Citus
CREATE EXTENSION IF NOT EXISTS citus;

-- Add worker nodes to the cluster
SELECT citus_add_node('worker1_market', 5432);
SELECT citus_add_node('worker2_market', 5432);

-- ==================================================
-- DATABASE SCHEMA FOR MARKET SERVICE
-- ==================================================

-- Create database schemas
CREATE SCHEMA IF NOT EXISTS market_core;
CREATE SCHEMA IF NOT EXISTS market_data;
CREATE SCHEMA IF NOT EXISTS market_analytics;

-- ==================================================
-- CORE TABLES
-- ==================================================

-- Market instruments table
CREATE TABLE market_core.instruments (
    instrument_id BIGSERIAL PRIMARY KEY,
    symbol VARCHAR(20) UNIQUE NOT NULL,
    instrument_name VARCHAR(255) NOT NULL,
    instrument_type VARCHAR(50) NOT NULL, -- stock, bond, commodity, forex, crypto, derivative
    exchange_id BIGINT,
    sector VARCHAR(100),
    industry VARCHAR(100),
    currency_code VARCHAR(3) DEFAULT 'USD',
    lot_size INTEGER DEFAULT 1,
    tick_size DECIMAL(10,8) DEFAULT 0.01,
    trading_hours VARCHAR(50),
    is_active BOOLEAN DEFAULT TRUE,
    listed_date DATE,
    delisted_date DATE,
    description TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Exchanges table
CREATE TABLE market_core.exchanges (
    exchange_id BIGSERIAL PRIMARY KEY,
    exchange_code VARCHAR(10) UNIQUE NOT NULL,
    exchange_name VARCHAR(100) NOT NULL,
    country_code VARCHAR(2),
    timezone VARCHAR(50),
    trading_hours VARCHAR(100),
    currency_code VARCHAR(3),
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Market data - price history
CREATE TABLE market_data.price_history (
    price_id BIGSERIAL PRIMARY KEY,
    instrument_id BIGINT NOT NULL,
    price_date DATE NOT NULL,
    price_time TIME,
    open_price DECIMAL(15,8),
    high_price DECIMAL(15,8),
    low_price DECIMAL(15,8),
    close_price DECIMAL(15,8) NOT NULL,
    volume BIGINT DEFAULT 0,
    turnover DECIMAL(20,2) DEFAULT 0,
    vwap DECIMAL(15,8), -- volume weighted average price
    price_change DECIMAL(15,8),
    price_change_percent DECIMAL(8,4),
    data_source VARCHAR(50),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Real-time market data
CREATE TABLE market_data.real_time_quotes (
    quote_id BIGSERIAL PRIMARY KEY,
    instrument_id BIGINT NOT NULL,
    quote_timestamp TIMESTAMP NOT NULL,
    bid_price DECIMAL(15,8),
    ask_price DECIMAL(15,8),
    bid_size BIGINT,
    ask_size BIGINT,
    last_price DECIMAL(15,8),
    last_size BIGINT,
    volume BIGINT DEFAULT 0,
    turnover DECIMAL(20,2) DEFAULT 0,
    high_price DECIMAL(15,8),
    low_price DECIMAL(15,8),
    open_price DECIMAL(15,8),
    previous_close DECIMAL(15,8),
    price_change DECIMAL(15,8),
    price_change_percent DECIMAL(8,4),
    data_source VARCHAR(50),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Market indices
CREATE TABLE market_core.indices (
    index_id BIGSERIAL PRIMARY KEY,
    index_code VARCHAR(20) UNIQUE NOT NULL,
    index_name VARCHAR(100) NOT NULL,
    index_type VARCHAR(50), -- price_weighted, market_cap_weighted, equal_weighted
    base_value DECIMAL(15,2) DEFAULT 100,
    base_date DATE,
    currency_code VARCHAR(3) DEFAULT 'USD',
    calculation_method TEXT,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Index constituents
CREATE TABLE market_core.index_constituents (
    constituent_id BIGSERIAL PRIMARY KEY,
    index_id BIGINT NOT NULL,
    instrument_id BIGINT NOT NULL,
    weight_percent DECIMAL(8,4),
    shares_outstanding BIGINT,
    effective_date DATE NOT NULL,
    end_date DATE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Index values history
CREATE TABLE market_data.index_values (
    value_id BIGSERIAL PRIMARY KEY,
    index_id BIGINT NOT NULL,
    value_date DATE NOT NULL,
    value_time TIME,
    index_value DECIMAL(15,4) NOT NULL,
    index_change DECIMAL(15,4),
    index_change_percent DECIMAL(8,4),
    volume BIGINT DEFAULT 0,
    market_cap DECIMAL(20,2),
    data_source VARCHAR(50),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Market news and events
CREATE TABLE market_data.market_news (
    news_id BIGSERIAL PRIMARY KEY,
    headline VARCHAR(500) NOT NULL,
    content TEXT,
    news_source VARCHAR(100),
    publish_date TIMESTAMP NOT NULL,
    category VARCHAR(100),
    sentiment VARCHAR(20), -- positive, negative, neutral
    sentiment_score DECIMAL(3,2),
    instruments_mentioned TEXT[], -- array of instrument symbols
    impact_level VARCHAR(20), -- low, medium, high
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Economic indicators
CREATE TABLE market_data.economic_indicators (
    indicator_id BIGSERIAL PRIMARY KEY,
    indicator_code VARCHAR(50) UNIQUE NOT NULL,
    indicator_name VARCHAR(255) NOT NULL,
    country_code VARCHAR(2),
    category VARCHAR(100),
    frequency VARCHAR(20), -- daily, weekly, monthly, quarterly, annually
    unit VARCHAR(50),
    description TEXT,
    data_source VARCHAR(100),
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Economic indicator values
CREATE TABLE market_data.indicator_values (
    value_id BIGSERIAL PRIMARY KEY,
    indicator_id BIGINT NOT NULL,
    value_date DATE NOT NULL,
    actual_value DECIMAL(15,4),
    forecast_value DECIMAL(15,4),
    previous_value DECIMAL(15,4),
    revised_value DECIMAL(15,4),
    data_source VARCHAR(100),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Trading sessions and market status
CREATE TABLE market_core.trading_sessions (
    session_id BIGSERIAL PRIMARY KEY,
    exchange_id BIGINT NOT NULL,
    session_date DATE NOT NULL,
    session_type VARCHAR(50) NOT NULL, -- pre_market, regular, after_hours, closed
    start_time TIME,
    end_time TIME,
    status VARCHAR(20) DEFAULT 'scheduled', -- scheduled, open, closed, halted
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Market analytics - technical indicators
CREATE TABLE market_analytics.technical_indicators (
    indicator_id BIGSERIAL PRIMARY KEY,
    instrument_id BIGINT NOT NULL,
    calculation_date DATE NOT NULL,
    indicator_type VARCHAR(50) NOT NULL, -- sma, ema, rsi, macd, bollinger_bands, etc.
    period_length INTEGER,
    indicator_value DECIMAL(15,8),
    additional_values JSONB, -- for complex indicators with multiple values
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Portfolio tracking
CREATE TABLE market_core.portfolios (
    portfolio_id BIGSERIAL PRIMARY KEY,
    portfolio_name VARCHAR(100) NOT NULL,
    portfolio_type VARCHAR(50), -- individual, institutional, fund, index
    base_currency VARCHAR(3) DEFAULT 'USD',
    manager_id BIGINT,
    inception_date DATE,
    total_value DECIMAL(20,2) DEFAULT 0,
    cash_position DECIMAL(20,2) DEFAULT 0,
    status VARCHAR(20) DEFAULT 'active',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Portfolio holdings
CREATE TABLE market_core.portfolio_holdings (
    holding_id BIGSERIAL PRIMARY KEY,
    portfolio_id BIGINT NOT NULL,
    instrument_id BIGINT NOT NULL,
    quantity DECIMAL(18,6) NOT NULL,
    average_cost DECIMAL(15,8),
    current_price DECIMAL(15,8),
    market_value DECIMAL(20,2),
    unrealized_pnl DECIMAL(20,2),
    weight_percent DECIMAL(8,4),
    last_updated TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ==================================================
-- DISTRIBUTE TABLES
-- ==================================================

-- Distribute tables across worker nodes
SELECT create_distributed_table('market_core.instruments', 'instrument_id');
SELECT create_distributed_table('market_core.exchanges', 'exchange_id');
SELECT create_distributed_table('market_data.price_history', 'instrument_id');
SELECT create_distributed_table('market_data.real_time_quotes', 'instrument_id');
SELECT create_distributed_table('market_core.indices', 'index_id');
SELECT create_distributed_table('market_core.index_constituents', 'index_id');
SELECT create_distributed_table('market_data.index_values', 'index_id');
SELECT create_distributed_table('market_data.market_news', 'news_id');
SELECT create_distributed_table('market_data.economic_indicators', 'indicator_id');
SELECT create_distributed_table('market_data.indicator_values', 'indicator_id');
SELECT create_distributed_table('market_core.trading_sessions', 'exchange_id');
SELECT create_distributed_table('market_analytics.technical_indicators', 'instrument_id');
SELECT create_distributed_table('market_core.portfolios', 'portfolio_id');
SELECT create_distributed_table('market_core.portfolio_holdings', 'portfolio_id');

-- ==================================================
-- INDEXES
-- ==================================================

CREATE INDEX idx_instruments_symbol ON market_core.instruments(symbol);
CREATE INDEX idx_instruments_type ON market_core.instruments(instrument_type, exchange_id);
CREATE INDEX idx_price_history_date ON market_data.price_history(instrument_id, price_date DESC);
CREATE INDEX idx_real_time_quotes_timestamp ON market_data.real_time_quotes(instrument_id, quote_timestamp DESC);
CREATE INDEX idx_index_constituents_effective ON market_core.index_constituents(index_id, effective_date, end_date);
CREATE INDEX idx_index_values_date ON market_data.index_values(index_id, value_date DESC);
CREATE INDEX idx_market_news_date ON market_data.market_news(publish_date DESC);
CREATE INDEX idx_market_news_sentiment ON market_data.market_news(sentiment, impact_level);
CREATE INDEX idx_indicator_values_date ON market_data.indicator_values(indicator_id, value_date DESC);
CREATE INDEX idx_trading_sessions_date ON market_core.trading_sessions(exchange_id, session_date);
CREATE INDEX idx_technical_indicators_date ON market_analytics.technical_indicators(instrument_id, calculation_date DESC);
CREATE INDEX idx_portfolio_holdings_portfolio ON market_core.portfolio_holdings(portfolio_id, instrument_id);

-- ==================================================
-- SAMPLE DATA
-- ==================================================

-- Insert exchanges
INSERT INTO market_core.exchanges (exchange_code, exchange_name, country_code, timezone, trading_hours, currency_code) VALUES
('NYSE', 'New York Stock Exchange', 'US', 'America/New_York', '09:30-16:00', 'USD'),
('NASDAQ', 'NASDAQ Global Market', 'US', 'America/New_York', '09:30-16:00', 'USD'),
('LSE', 'London Stock Exchange', 'GB', 'Europe/London', '08:00-16:30', 'GBP'),
('TSE', 'Tokyo Stock Exchange', 'JP', 'Asia/Tokyo', '09:00-15:00', 'JPY'),
('SSE', 'Shanghai Stock Exchange', 'CN', 'Asia/Shanghai', '09:30-15:00', 'CNY');

-- Insert sample instruments
INSERT INTO market_core.instruments (symbol, instrument_name, instrument_type, exchange_id, sector, industry, currency_code, lot_size, tick_size) VALUES
('AAPL', 'Apple Inc.', 'stock', 2, 'Technology', 'Consumer Electronics', 'USD', 100, 0.01),
('MSFT', 'Microsoft Corporation', 'stock', 2, 'Technology', 'Software', 'USD', 100, 0.01),
('GOOGL', 'Alphabet Inc.', 'stock', 2, 'Technology', 'Internet Services', 'USD', 100, 0.01),
('TSLA', 'Tesla Inc.', 'stock', 2, 'Automotive', 'Electric Vehicles', 'USD', 100, 0.01),
('JPM', 'JPMorgan Chase & Co.', 'stock', 1, 'Financial', 'Banking', 'USD', 100, 0.01),
('EURUSD', 'Euro/US Dollar', 'forex', NULL, 'Currency', 'Major Pairs', 'USD', 100000, 0.00001),
('GOLD', 'Gold Spot', 'commodity', NULL, 'Commodity', 'Precious Metals', 'USD', 100, 0.01),
('BTC-USD', 'Bitcoin', 'crypto', NULL, 'Cryptocurrency', 'Digital Currency', 'USD', 1, 0.01);

-- Insert market indices
INSERT INTO market_core.indices (index_code, index_name, index_type, base_value, base_date, currency_code) VALUES
('SPX', 'S&P 500', 'market_cap_weighted', 100, '1957-03-04', 'USD'),
('DJI', 'Dow Jones Industrial Average', 'price_weighted', 100, '1896-05-26', 'USD'),
('IXIC', 'NASDAQ Composite', 'market_cap_weighted', 100, '1971-02-05', 'USD'),
('FTSE', 'FTSE 100', 'market_cap_weighted', 1000, '1984-01-03', 'GBP'),
('N225', 'Nikkei 225', 'price_weighted', 176.21, '1950-09-07', 'JPY');

-- Insert sample price history
INSERT INTO market_data.price_history (instrument_id, price_date, open_price, high_price, low_price, close_price, volume, price_change, price_change_percent) VALUES
(1, '2024-03-01', 180.50, 182.30, 179.80, 181.75, 45678900, 1.25, 0.69),
(2, '2024-03-01', 410.20, 415.80, 408.50, 412.90, 23456780, 2.70, 0.66),
(3, '2024-03-01', 138.40, 140.20, 137.60, 139.85, 18765432, 1.45, 1.05),
(4, '2024-03-01', 205.30, 208.90, 203.50, 207.75, 67890123, 2.45, 1.19),
(5, '2024-03-01', 165.80, 167.40, 164.20, 166.95, 12345678, 1.15, 0.69);

-- Insert economic indicators
INSERT INTO market_data.economic_indicators (indicator_code, indicator_name, country_code, category, frequency, unit, description) VALUES
('GDP_US', 'Gross Domestic Product', 'US', 'Economic Growth', 'quarterly', 'Trillion USD', 'US Gross Domestic Product'),
('CPI_US', 'Consumer Price Index', 'US', 'Inflation', 'monthly', 'Index', 'US Consumer Price Index'),
('UNEMPLOYMENT_US', 'Unemployment Rate', 'US', 'Employment', 'monthly', 'Percent', 'US Unemployment Rate'),
('FED_RATE', 'Federal Funds Rate', 'US', 'Interest Rate', 'irregular', 'Percent', 'US Federal Funds Rate'),
('VIX', 'Volatility Index', 'US', 'Market Sentiment', 'daily', 'Index', 'CBOE Volatility Index');

-- Insert sample indicator values
INSERT INTO market_data.indicator_values (indicator_id, value_date, actual_value, forecast_value, previous_value) VALUES
(1, '2024-01-31', 27.5, 27.3, 27.2),
(2, '2024-02-29', 3.2, 3.1, 3.1),
(3, '2024-02-29', 3.9, 3.8, 3.7),
(4, '2024-03-20', 5.25, 5.25, 5.00),
(5, '2024-03-01', 18.45, NULL, 17.20);

-- Insert sample portfolios
INSERT INTO market_core.portfolios (portfolio_name, portfolio_type, base_currency, inception_date, total_value, cash_position) VALUES
('Tech Growth Portfolio', 'individual', 'USD', '2024-01-01', 1000000.00, 50000.00),
('Balanced Fund', 'fund', 'USD', '2023-01-01', 5000000.00, 250000.00),
('Conservative Income', 'institutional', 'USD', '2022-01-01', 10000000.00, 500000.00);

-- Insert sample portfolio holdings
INSERT INTO market_core.portfolio_holdings (portfolio_id, instrument_id, quantity, average_cost, current_price, market_value, unrealized_pnl, weight_percent) VALUES
(1, 1, 1000, 175.50, 181.75, 181750.00, 6250.00, 18.18),
(1, 2, 500, 400.00, 412.90, 206450.00, 6450.00, 20.65),
(1, 3, 800, 135.00, 139.85, 111880.00, 3880.00, 11.19),
(1, 4, 300, 200.00, 207.75, 62325.00, 2325.00, 6.23);

-- Insert sample market news
INSERT INTO market_data.market_news (headline, content, news_source, publish_date, category, sentiment, sentiment_score, instruments_mentioned, impact_level) VALUES
('Tech Stocks Rally on Strong Earnings Reports', 'Major technology companies reported better than expected earnings...', 'MarketWatch', '2024-03-01 09:30:00', 'Earnings', 'positive', 0.75, '{"AAPL","MSFT","GOOGL"}', 'medium'),
('Federal Reserve Maintains Interest Rates', 'The Federal Reserve decided to keep interest rates unchanged...', 'Reuters', '2024-03-20 14:00:00', 'Monetary Policy', 'neutral', 0.00, '{"SPX","DJI"}', 'high'),
('Oil Prices Surge on Supply Concerns', 'Crude oil prices jumped 5% following reports of supply disruptions...', 'Bloomberg', '2024-03-15 11:45:00', 'Commodities', 'negative', -0.60, '{"GOLD"}', 'medium');

COMMENT ON DATABASE postgres IS 'Market Data and Analysis System Database - Citus Distributed';
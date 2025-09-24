-- ==================================================
-- INIT SQL FOR CITUS COORDINATOR - FINANCE SERVICE
-- Financial Management Database
-- ==================================================

-- Create extension for Citus
CREATE EXTENSION IF NOT EXISTS citus;

-- Add worker nodes to the cluster
SELECT citus_add_node('worker1_finance', 5432);
SELECT citus_add_node('worker2_finance', 5432);

-- ==================================================
-- DATABASE SCHEMA FOR FINANCE SERVICE
-- ==================================================

-- Create database schemas
CREATE SCHEMA IF NOT EXISTS finance_core;
CREATE SCHEMA IF NOT EXISTS finance_accounting;
CREATE SCHEMA IF NOT EXISTS finance_reporting;

-- ==================================================
-- CORE TABLES
-- ==================================================

-- Chart of Accounts table
CREATE TABLE finance_accounting.chart_of_accounts (
    account_id BIGSERIAL PRIMARY KEY,
    account_code VARCHAR(20) UNIQUE NOT NULL,
    account_name VARCHAR(100) NOT NULL,
    account_type VARCHAR(50) NOT NULL, -- asset, liability, equity, revenue, expense
    parent_account_id BIGINT,
    level_number INTEGER DEFAULT 1,
    is_active BOOLEAN DEFAULT TRUE,
    description TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- General Ledger table
CREATE TABLE finance_accounting.general_ledger (
    entry_id BIGSERIAL PRIMARY KEY,
    transaction_id BIGINT NOT NULL,
    account_id BIGINT NOT NULL,
    debit_amount DECIMAL(15,2) DEFAULT 0,
    credit_amount DECIMAL(15,2) DEFAULT 0,
    description TEXT,
    reference_number VARCHAR(50),
    transaction_date DATE NOT NULL,
    posted_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    period_year INTEGER,
    period_month INTEGER,
    created_by BIGINT NOT NULL
);

-- Transactions table
CREATE TABLE finance_core.transactions (
    transaction_id BIGSERIAL PRIMARY KEY,
    transaction_number VARCHAR(50) UNIQUE NOT NULL,
    transaction_type VARCHAR(50) NOT NULL,
    transaction_date DATE NOT NULL,
    description TEXT,
    reference_number VARCHAR(50),
    total_amount DECIMAL(15,2) NOT NULL,
    currency_code VARCHAR(3) DEFAULT 'USD',
    exchange_rate DECIMAL(10,4) DEFAULT 1.0000,
    status VARCHAR(20) DEFAULT 'pending',
    created_by BIGINT NOT NULL,
    approved_by BIGINT,
    approved_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Budgets table
CREATE TABLE finance_core.budgets (
    budget_id BIGSERIAL PRIMARY KEY,
    budget_code VARCHAR(20) UNIQUE NOT NULL,
    budget_name VARCHAR(100) NOT NULL,
    budget_year INTEGER NOT NULL,
    budget_type VARCHAR(50) NOT NULL, -- operational, capital, project
    department_id BIGINT,
    total_amount DECIMAL(15,2) NOT NULL,
    status VARCHAR(20) DEFAULT 'draft',
    created_by BIGINT NOT NULL,
    approved_by BIGINT,
    approved_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Budget line items table
CREATE TABLE finance_core.budget_line_items (
    line_item_id BIGSERIAL PRIMARY KEY,
    budget_id BIGINT NOT NULL,
    account_id BIGINT NOT NULL,
    line_item_name VARCHAR(100) NOT NULL,
    budgeted_amount DECIMAL(15,2) NOT NULL,
    actual_amount DECIMAL(15,2) DEFAULT 0,
    variance_amount DECIMAL(15,2) DEFAULT 0,
    quarter_1 DECIMAL(15,2) DEFAULT 0,
    quarter_2 DECIMAL(15,2) DEFAULT 0,
    quarter_3 DECIMAL(15,2) DEFAULT 0,
    quarter_4 DECIMAL(15,2) DEFAULT 0,
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Invoices table
CREATE TABLE finance_core.invoices (
    invoice_id BIGSERIAL PRIMARY KEY,
    invoice_number VARCHAR(50) UNIQUE NOT NULL,
    invoice_type VARCHAR(20) NOT NULL, -- receivable, payable
    customer_vendor_id BIGINT NOT NULL,
    invoice_date DATE NOT NULL,
    due_date DATE NOT NULL,
    subtotal DECIMAL(15,2) NOT NULL,
    tax_amount DECIMAL(15,2) DEFAULT 0,
    discount_amount DECIMAL(15,2) DEFAULT 0,
    total_amount DECIMAL(15,2) NOT NULL,
    paid_amount DECIMAL(15,2) DEFAULT 0,
    balance_amount DECIMAL(15,2) NOT NULL,
    currency_code VARCHAR(3) DEFAULT 'USD',
    status VARCHAR(20) DEFAULT 'pending',
    payment_terms VARCHAR(50),
    notes TEXT,
    created_by BIGINT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Invoice line items table
CREATE TABLE finance_core.invoice_line_items (
    line_item_id BIGSERIAL PRIMARY KEY,
    invoice_id BIGINT NOT NULL,
    product_service_id BIGINT,
    description TEXT NOT NULL,
    quantity DECIMAL(10,3) DEFAULT 1,
    unit_price DECIMAL(15,2) NOT NULL,
    line_total DECIMAL(15,2) NOT NULL,
    tax_rate DECIMAL(5,4) DEFAULT 0,
    tax_amount DECIMAL(15,2) DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Payments table
CREATE TABLE finance_core.payments (
    payment_id BIGSERIAL PRIMARY KEY,
    payment_number VARCHAR(50) UNIQUE NOT NULL,
    invoice_id BIGINT NOT NULL,
    payment_method VARCHAR(50) NOT NULL,
    payment_date DATE NOT NULL,
    amount DECIMAL(15,2) NOT NULL,
    currency_code VARCHAR(3) DEFAULT 'USD',
    exchange_rate DECIMAL(10,4) DEFAULT 1.0000,
    reference_number VARCHAR(50),
    notes TEXT,
    status VARCHAR(20) DEFAULT 'pending',
    processed_by BIGINT NOT NULL,
    processed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Financial periods table
CREATE TABLE finance_core.financial_periods (
    period_id BIGSERIAL PRIMARY KEY,
    period_name VARCHAR(50) NOT NULL,
    period_year INTEGER NOT NULL,
    period_month INTEGER NOT NULL,
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    status VARCHAR(20) DEFAULT 'open',
    closed_by BIGINT,
    closed_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ==================================================
-- DISTRIBUTE TABLES
-- ==================================================

-- Distribute tables across worker nodes
SELECT create_distributed_table('finance_accounting.chart_of_accounts', 'account_id');
SELECT create_distributed_table('finance_accounting.general_ledger', 'account_id');
SELECT create_distributed_table('finance_core.transactions', 'transaction_id');
SELECT create_distributed_table('finance_core.budgets', 'budget_id');
SELECT create_distributed_table('finance_core.budget_line_items', 'budget_id');
SELECT create_distributed_table('finance_core.invoices', 'invoice_id');
SELECT create_distributed_table('finance_core.invoice_line_items', 'invoice_id');
SELECT create_distributed_table('finance_core.payments', 'payment_id');
SELECT create_distributed_table('finance_core.financial_periods', 'period_id');

-- ==================================================
-- INDEXES
-- ==================================================

CREATE INDEX idx_general_ledger_transaction ON finance_accounting.general_ledger(transaction_id);
CREATE INDEX idx_general_ledger_account ON finance_accounting.general_ledger(account_id, transaction_date);
CREATE INDEX idx_general_ledger_period ON finance_accounting.general_ledger(period_year, period_month);
CREATE INDEX idx_transactions_date ON finance_core.transactions(transaction_date);
CREATE INDEX idx_transactions_type ON finance_core.transactions(transaction_type, status);
CREATE INDEX idx_budgets_year ON finance_core.budgets(budget_year, department_id);
CREATE INDEX idx_budget_line_items_account ON finance_core.budget_line_items(budget_id, account_id);
CREATE INDEX idx_invoices_date ON finance_core.invoices(invoice_date, due_date);
CREATE INDEX idx_invoices_status ON finance_core.invoices(status, invoice_type);
CREATE INDEX idx_payments_date ON finance_core.payments(payment_date, invoice_id);
CREATE INDEX idx_financial_periods_date ON finance_core.financial_periods(period_year, period_month);

-- ==================================================
-- SAMPLE DATA
-- ==================================================

-- Insert chart of accounts
INSERT INTO finance_accounting.chart_of_accounts (account_code, account_name, account_type, level_number, description) VALUES
-- Assets
('1000', 'Assets', 'asset', 1, 'Total Assets'),
('1100', 'Current Assets', 'asset', 2, 'Current Assets'),
('1110', 'Cash and Cash Equivalents', 'asset', 3, 'Cash and Cash Equivalents'),
('1120', 'Accounts Receivable', 'asset', 3, 'Accounts Receivable'),
('1130', 'Inventory', 'asset', 3, 'Inventory'),
-- Liabilities
('2000', 'Liabilities', 'liability', 1, 'Total Liabilities'),
('2100', 'Current Liabilities', 'liability', 2, 'Current Liabilities'),
('2110', 'Accounts Payable', 'liability', 3, 'Accounts Payable'),
('2120', 'Accrued Expenses', 'liability', 3, 'Accrued Expenses'),
-- Equity
('3000', 'Equity', 'equity', 1, 'Total Equity'),
('3100', 'Retained Earnings', 'equity', 2, 'Retained Earnings'),
-- Revenue
('4000', 'Revenue', 'revenue', 1, 'Total Revenue'),
('4100', 'Sales Revenue', 'revenue', 2, 'Sales Revenue'),
('4200', 'Service Revenue', 'revenue', 2, 'Service Revenue'),
-- Expenses
('5000', 'Expenses', 'expense', 1, 'Total Expenses'),
('5100', 'Cost of Goods Sold', 'expense', 2, 'Cost of Goods Sold'),
('5200', 'Operating Expenses', 'expense', 2, 'Operating Expenses'),
('5210', 'Salaries and Wages', 'expense', 3, 'Salaries and Wages'),
('5220', 'Rent Expense', 'expense', 3, 'Rent Expense'),
('5230', 'Utilities Expense', 'expense', 3, 'Utilities Expense');

-- Insert financial periods
INSERT INTO finance_core.financial_periods (period_name, period_year, period_month, start_date, end_date, status) VALUES
('January 2024', 2024, 1, '2024-01-01', '2024-01-31', 'closed'),
('February 2024', 2024, 2, '2024-02-01', '2024-02-29', 'closed'),
('March 2024', 2024, 3, '2024-03-01', '2024-03-31', 'closed'),
('April 2024', 2024, 4, '2024-04-01', '2024-04-30', 'open'),
('May 2024', 2024, 5, '2024-05-01', '2024-05-31', 'open');

-- Insert sample budgets
INSERT INTO finance_core.budgets (budget_code, budget_name, budget_year, budget_type, total_amount, status, created_by) VALUES
('B2024-001', 'Operating Budget 2024', 2024, 'operational', 1000000.00, 'approved', 1),
('B2024-002', 'Capital Budget 2024', 2024, 'capital', 500000.00, 'approved', 1),
('B2024-003', 'Marketing Budget 2024', 2024, 'operational', 200000.00, 'draft', 1);

-- Insert sample transactions
INSERT INTO finance_core.transactions (transaction_number, transaction_type, transaction_date, description, total_amount, status, created_by) VALUES
('TXN001', 'sales', '2024-03-01', 'Product sales transaction', 5000.00, 'posted', 1),
('TXN002', 'expense', '2024-03-02', 'Office rent payment', 2000.00, 'posted', 1),
('TXN003', 'purchase', '2024-03-03', 'Inventory purchase', 3000.00, 'pending', 1);

-- Insert sample invoices
INSERT INTO finance_core.invoices (invoice_number, invoice_type, customer_vendor_id, invoice_date, due_date, subtotal, tax_amount, total_amount, balance_amount, created_by) VALUES
('INV-001', 'receivable', 1, '2024-03-01', '2024-03-31', 4500.00, 500.00, 5000.00, 5000.00, 1),
('INV-002', 'payable', 2, '2024-03-02', '2024-04-01', 2700.00, 300.00, 3000.00, 3000.00, 1);

COMMENT ON DATABASE postgres IS 'Financial Management System Database - Citus Distributed';
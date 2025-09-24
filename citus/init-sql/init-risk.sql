-- ==================================================
-- INIT SQL FOR CITUS COORDINATOR - RISK SERVICE
-- Risk Management Database
-- ==================================================

-- Create extension for Citus
CREATE EXTENSION IF NOT EXISTS citus;

-- Add worker nodes to the cluster
SELECT citus_add_node('worker1_risk', 5432);
SELECT citus_add_node('worker2_risk', 5432);

-- ==================================================
-- DATABASE SCHEMA FOR RISK SERVICE
-- ==================================================

-- Create database schemas
CREATE SCHEMA IF NOT EXISTS risk_core;
CREATE SCHEMA IF NOT EXISTS risk_assessment;
CREATE SCHEMA IF NOT EXISTS risk_monitoring;

-- ==================================================
-- CORE TABLES
-- ==================================================

-- Risk categories table
CREATE TABLE risk_core.risk_categories (
    category_id BIGSERIAL PRIMARY KEY,
    category_code VARCHAR(20) UNIQUE NOT NULL,
    category_name VARCHAR(100) NOT NULL,
    parent_category_id BIGINT,
    description TEXT,
    severity_weight DECIMAL(3,2) DEFAULT 1.00,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Risk registers table
CREATE TABLE risk_core.risk_registers (
    risk_id BIGSERIAL PRIMARY KEY,
    risk_code VARCHAR(50) UNIQUE NOT NULL,
    risk_title VARCHAR(255) NOT NULL,
    risk_description TEXT NOT NULL,
    category_id BIGINT NOT NULL,
    risk_type VARCHAR(50) NOT NULL, -- operational, financial, strategic, compliance, reputation
    business_unit VARCHAR(100),
    risk_owner_id BIGINT NOT NULL,
    identified_date DATE NOT NULL,
    status VARCHAR(20) DEFAULT 'active', -- active, mitigated, closed, transferred
    likelihood INTEGER CHECK (likelihood >= 1 AND likelihood <= 5), -- 1=rare, 5=almost certain
    impact INTEGER CHECK (impact >= 1 AND impact <= 5), -- 1=insignificant, 5=catastrophic
    inherent_risk_score INTEGER GENERATED ALWAYS AS (likelihood * impact) STORED,
    residual_likelihood INTEGER,
    residual_impact INTEGER,
    residual_risk_score INTEGER GENERATED ALWAYS AS (residual_likelihood * residual_impact) STORED,
    risk_appetite VARCHAR(20), -- low, medium, high
    review_date DATE,
    created_by BIGINT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Risk assessments table
CREATE TABLE risk_assessment.assessments (
    assessment_id BIGSERIAL PRIMARY KEY,
    risk_id BIGINT NOT NULL,
    assessment_date DATE NOT NULL,
    assessor_id BIGINT NOT NULL,
    assessment_type VARCHAR(50) NOT NULL, -- initial, periodic, incident_driven
    likelihood_score INTEGER CHECK (likelihood_score >= 1 AND likelihood_score <= 5),
    impact_score INTEGER CHECK (impact_score >= 1 AND impact_score <= 5),
    overall_score INTEGER GENERATED ALWAYS AS (likelihood_score * impact_score) STORED,
    assessment_notes TEXT,
    recommendations TEXT,
    status VARCHAR(20) DEFAULT 'draft',
    approved_by BIGINT,
    approved_at TIMESTAMP,
    next_review_date DATE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Risk controls table
CREATE TABLE risk_core.risk_controls (
    control_id BIGSERIAL PRIMARY KEY,
    risk_id BIGINT NOT NULL,
    control_code VARCHAR(50) UNIQUE NOT NULL,
    control_name VARCHAR(255) NOT NULL,
    control_description TEXT NOT NULL,
    control_type VARCHAR(50) NOT NULL, -- preventive, detective, corrective
    control_frequency VARCHAR(50), -- daily, weekly, monthly, quarterly, annually
    control_owner_id BIGINT NOT NULL,
    implementation_date DATE,
    effectiveness_rating INTEGER CHECK (effectiveness_rating >= 1 AND effectiveness_rating <= 5),
    status VARCHAR(20) DEFAULT 'active',
    last_tested_date DATE,
    next_test_date DATE,
    created_by BIGINT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Risk control testing table
CREATE TABLE risk_assessment.control_testing (
    test_id BIGSERIAL PRIMARY KEY,
    control_id BIGINT NOT NULL,
    test_date DATE NOT NULL,
    tester_id BIGINT NOT NULL,
    test_method VARCHAR(100),
    test_sample_size INTEGER,
    exceptions_found INTEGER DEFAULT 0,
    test_result VARCHAR(20) NOT NULL, -- effective, ineffective, partially_effective
    effectiveness_score INTEGER CHECK (effectiveness_score >= 1 AND effectiveness_score <= 5),
    findings TEXT,
    recommendations TEXT,
    remediation_required BOOLEAN DEFAULT FALSE,
    remediation_deadline DATE,
    status VARCHAR(20) DEFAULT 'completed',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Risk incidents table
CREATE TABLE risk_monitoring.incidents (
    incident_id BIGSERIAL PRIMARY KEY,
    incident_code VARCHAR(50) UNIQUE NOT NULL,
    risk_id BIGINT,
    incident_title VARCHAR(255) NOT NULL,
    incident_description TEXT NOT NULL,
    incident_date DATE NOT NULL,
    reported_by BIGINT NOT NULL,
    reported_date DATE NOT NULL,
    severity VARCHAR(20) NOT NULL, -- low, medium, high, critical
    impact_amount DECIMAL(15,2),
    business_impact TEXT,
    root_cause TEXT,
    immediate_action TEXT,
    status VARCHAR(20) DEFAULT 'open', -- open, investigating, resolved, closed
    assigned_to BIGINT,
    resolution_date DATE,
    resolution_notes TEXT,
    lessons_learned TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Risk mitigation plans table
CREATE TABLE risk_core.mitigation_plans (
    plan_id BIGSERIAL PRIMARY KEY,
    risk_id BIGINT NOT NULL,
    plan_name VARCHAR(255) NOT NULL,
    mitigation_strategy VARCHAR(100) NOT NULL, -- avoid, reduce, transfer, accept
    action_description TEXT NOT NULL,
    responsible_person_id BIGINT NOT NULL,
    target_start_date DATE,
    target_completion_date DATE,
    actual_completion_date DATE,
    budget_allocated DECIMAL(15,2),
    budget_spent DECIMAL(15,2) DEFAULT 0,
    expected_risk_reduction INTEGER, -- percentage
    status VARCHAR(20) DEFAULT 'planned', -- planned, in_progress, completed, cancelled
    progress_notes TEXT,
    created_by BIGINT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Risk monitoring dashboard data
CREATE TABLE risk_monitoring.risk_metrics (
    metric_id BIGSERIAL PRIMARY KEY,
    metric_date DATE NOT NULL,
    total_risks INTEGER DEFAULT 0,
    high_risk_count INTEGER DEFAULT 0,
    medium_risk_count INTEGER DEFAULT 0,
    low_risk_count INTEGER DEFAULT 0,
    overdue_assessments INTEGER DEFAULT 0,
    overdue_controls INTEGER DEFAULT 0,
    open_incidents INTEGER DEFAULT 0,
    avg_risk_score DECIMAL(4,2),
    risk_appetite_breach_count INTEGER DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ==================================================
-- DISTRIBUTE TABLES
-- ==================================================

-- Distribute tables across worker nodes
SELECT create_distributed_table('risk_core.risk_categories', 'category_id');
SELECT create_distributed_table('risk_core.risk_registers', 'risk_id');
SELECT create_distributed_table('risk_assessment.assessments', 'risk_id');
SELECT create_distributed_table('risk_core.risk_controls', 'risk_id');
SELECT create_distributed_table('risk_assessment.control_testing', 'control_id');
SELECT create_distributed_table('risk_monitoring.incidents', 'incident_id');
SELECT create_distributed_table('risk_core.mitigation_plans', 'risk_id');
SELECT create_distributed_table('risk_monitoring.risk_metrics', 'metric_id');

-- ==================================================
-- INDEXES
-- ==================================================

CREATE INDEX idx_risk_registers_category ON risk_core.risk_registers(category_id);
CREATE INDEX idx_risk_registers_owner ON risk_core.risk_registers(risk_owner_id);
CREATE INDEX idx_risk_registers_score ON risk_core.risk_registers(inherent_risk_score DESC);
CREATE INDEX idx_risk_registers_status ON risk_core.risk_registers(status, review_date);
CREATE INDEX idx_assessments_date ON risk_assessment.assessments(risk_id, assessment_date DESC);
CREATE INDEX idx_controls_owner ON risk_core.risk_controls(risk_id, control_owner_id);
CREATE INDEX idx_controls_testing ON risk_core.risk_controls(next_test_date, status);
CREATE INDEX idx_control_testing_date ON risk_assessment.control_testing(control_id, test_date DESC);
CREATE INDEX idx_incidents_severity ON risk_monitoring.incidents(severity, status);
CREATE INDEX idx_incidents_date ON risk_monitoring.incidents(incident_date, reported_date);
CREATE INDEX idx_mitigation_plans_status ON risk_core.mitigation_plans(risk_id, status);
CREATE INDEX idx_risk_metrics_date ON risk_monitoring.risk_metrics(metric_date DESC);

-- ==================================================
-- SAMPLE DATA
-- ==================================================

-- Insert risk categories
INSERT INTO risk_core.risk_categories (category_code, category_name, description, severity_weight) VALUES
('OP', 'Operational Risk', 'Risks related to operational processes and systems', 1.00),
('FIN', 'Financial Risk', 'Risks related to financial losses and market fluctuations', 1.20),
('COMP', 'Compliance Risk', 'Risks related to regulatory and legal compliance', 1.10),
('TECH', 'Technology Risk', 'Risks related to IT systems and cybersecurity', 1.15),
('REP', 'Reputational Risk', 'Risks that could damage company reputation', 0.95),
('STRAT', 'Strategic Risk', 'Risks related to strategic decisions and market changes', 1.05);

-- Insert sample risks
INSERT INTO risk_core.risk_registers (risk_code, risk_title, risk_description, category_id, risk_type, business_unit, risk_owner_id, identified_date, likelihood, impact, residual_likelihood, residual_impact, risk_appetite) VALUES
('RISK-001', 'Data Breach', 'Risk of unauthorized access to customer data', 4, 'operational', 'IT Department', 1, '2024-01-15', 3, 5, 2, 4, 'low'),
('RISK-002', 'Market Volatility', 'Risk of financial losses due to market fluctuations', 2, 'financial', 'Finance', 1, '2024-01-20', 4, 4, 3, 3, 'medium'),
('RISK-003', 'Regulatory Changes', 'Risk of non-compliance due to changing regulations', 3, 'compliance', 'Legal', 1, '2024-02-01', 3, 4, 2, 3, 'low'),
('RISK-004', 'System Downtime', 'Risk of critical system failures affecting operations', 4, 'operational', 'IT Department', 1, '2024-02-10', 2, 4, 1, 3, 'medium'),
('RISK-005', 'Key Personnel Loss', 'Risk of losing critical staff members', 1, 'operational', 'HR', 1, '2024-02-15', 3, 3, 2, 2, 'high');

-- Insert sample controls
INSERT INTO risk_core.risk_controls (risk_id, control_code, control_name, control_description, control_type, control_frequency, control_owner_id, implementation_date, effectiveness_rating, last_tested_date, next_test_date, created_by) VALUES
(1, 'CTRL-001', 'Access Controls', 'Multi-factor authentication and role-based access controls', 'preventive', 'daily', 1, '2024-01-01', 4, '2024-03-01', '2024-06-01', 1),
(1, 'CTRL-002', 'Security Monitoring', 'Real-time monitoring of security events and alerts', 'detective', 'daily', 1, '2024-01-01', 4, '2024-03-15', '2024-06-15', 1),
(2, 'CTRL-003', 'Risk Limits', 'Daily monitoring of market risk exposure limits', 'preventive', 'daily', 1, '2024-01-01', 3, '2024-03-10', '2024-06-10', 1),
(3, 'CTRL-004', 'Compliance Monitoring', 'Regular review of regulatory requirements and compliance status', 'detective', 'monthly', 1, '2024-01-01', 3, '2024-03-01', '2024-06-01', 1),
(4, 'CTRL-005', 'System Backup', 'Automated backup and disaster recovery procedures', 'corrective', 'daily', 1, '2024-01-01', 4, '2024-03-05', '2024-06-05', 1);

-- Insert sample assessments
INSERT INTO risk_assessment.assessments (risk_id, assessment_date, assessor_id, assessment_type, likelihood_score, impact_score, assessment_notes, status, next_review_date) VALUES
(1, '2024-03-01', 1, 'periodic', 3, 5, 'Regular quarterly assessment. Controls are functioning well.', 'approved', '2024-06-01'),
(2, '2024-03-01', 1, 'periodic', 4, 4, 'Market conditions remain volatile. Monitoring continues.', 'approved', '2024-06-01'),
(3, '2024-03-01', 1, 'periodic', 3, 4, 'New regulations expected in Q3. Preparation in progress.', 'approved', '2024-06-01'),
(4, '2024-03-01', 1, 'periodic', 2, 4, 'System stability improved with recent upgrades.', 'approved', '2024-06-01'),
(5, '2024-03-01', 1, 'periodic', 3, 3, 'Succession planning initiatives underway.', 'approved', '2024-06-01');

-- Insert sample mitigation plans
INSERT INTO risk_core.mitigation_plans (risk_id, plan_name, mitigation_strategy, action_description, responsible_person_id, target_start_date, target_completion_date, budget_allocated, status, created_by) VALUES
(1, 'Enhanced Security Framework', 'reduce', 'Implement advanced threat detection and response capabilities', 1, '2024-04-01', '2024-09-30', 150000.00, 'planned', 1),
(2, 'Portfolio Diversification', 'reduce', 'Diversify investment portfolio to reduce market risk concentration', 1, '2024-04-01', '2024-12-31', 50000.00, 'in_progress', 1),
(3, 'Regulatory Compliance Program', 'reduce', 'Establish dedicated compliance monitoring and reporting system', 1, '2024-05-01', '2024-11-30', 75000.00, 'planned', 1),
(4, 'Infrastructure Upgrade', 'reduce', 'Upgrade critical systems and implement redundancy', 1, '2024-06-01', '2024-12-31', 200000.00, 'planned', 1),
(5, 'Talent Retention Program', 'reduce', 'Implement retention strategies and knowledge management', 1, '2024-04-01', '2024-08-31', 100000.00, 'in_progress', 1);

-- Insert sample incidents
INSERT INTO risk_monitoring.incidents (incident_code, risk_id, incident_title, incident_description, incident_date, reported_by, reported_date, severity, impact_amount, business_impact, root_cause, status, assigned_to) VALUES
('INC-001', 1, 'Failed Login Attempts', 'Multiple failed login attempts detected from unusual locations', '2024-03-15', 1, '2024-03-15', 'medium', 0, 'Minimal impact - blocked by security controls', 'Potential brute force attack', 'resolved', 1),
('INC-002', 4, 'Database Connection Issues', 'Intermittent database connectivity issues affecting user access', '2024-03-10', 1, '2024-03-10', 'high', 5000.00, 'Service disruption for 2 hours', 'Network configuration error', 'closed', 1);

-- Insert sample metrics
INSERT INTO risk_monitoring.risk_metrics (metric_date, total_risks, high_risk_count, medium_risk_count, low_risk_count, overdue_assessments, overdue_controls, open_incidents, avg_risk_score) VALUES
('2024-03-01', 5, 1, 3, 1, 0, 0, 0, 12.8),
('2024-03-15', 5, 1, 3, 1, 0, 0, 1, 12.8),
('2024-03-31', 5, 1, 3, 1, 0, 0, 0, 12.8);

COMMENT ON DATABASE postgres IS 'Risk Management System Database - Citus Distributed';
-- ==================================================
-- INIT SQL FOR CITUS COORDINATOR - HC SERVICE
-- Human Capital Management Database
-- ==================================================

-- Create extension for Citus
CREATE EXTENSION IF NOT EXISTS citus;

-- Add worker nodes to the cluster
SELECT citus_add_node('worker1_hc', 5432);
SELECT citus_add_node('worker2_hc', 5432);

-- ==================================================
-- DATABASE SCHEMA FOR HC SERVICE
-- ==================================================

-- Create database schemas
CREATE SCHEMA IF NOT EXISTS hc_core;
CREATE SCHEMA IF NOT EXISTS hc_reports;
CREATE SCHEMA IF NOT EXISTS hc_analytics;

-- ==================================================
-- CORE TABLES
-- ==================================================

-- Employees table
CREATE TABLE hc_core.employees (
    employee_id BIGSERIAL PRIMARY KEY,
    employee_code VARCHAR(20) UNIQUE NOT NULL,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    phone VARCHAR(20),
    hire_date DATE NOT NULL,
    department_id BIGINT,
    position_id BIGINT,
    manager_id BIGINT,
    salary DECIMAL(15,2),
    status VARCHAR(20) DEFAULT 'active',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Departments table
CREATE TABLE hc_core.departments (
    department_id BIGSERIAL PRIMARY KEY,
    department_code VARCHAR(20) UNIQUE NOT NULL,
    department_name VARCHAR(100) NOT NULL,
    description TEXT,
    manager_id BIGINT,
    budget DECIMAL(15,2),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Positions table
CREATE TABLE hc_core.positions (
    position_id BIGSERIAL PRIMARY KEY,
    position_code VARCHAR(20) UNIQUE NOT NULL,
    position_title VARCHAR(100) NOT NULL,
    department_id BIGINT,
    level_grade VARCHAR(10),
    min_salary DECIMAL(15,2),
    max_salary DECIMAL(15,2),
    description TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Attendance table
CREATE TABLE hc_core.attendance (
    attendance_id BIGSERIAL PRIMARY KEY,
    employee_id BIGINT NOT NULL,
    attendance_date DATE NOT NULL,
    check_in TIME,
    check_out TIME,
    work_hours DECIMAL(4,2),
    status VARCHAR(20) DEFAULT 'present',
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Leave requests table
CREATE TABLE hc_core.leave_requests (
    request_id BIGSERIAL PRIMARY KEY,
    employee_id BIGINT NOT NULL,
    leave_type VARCHAR(50) NOT NULL,
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    days_requested INTEGER NOT NULL,
    reason TEXT,
    status VARCHAR(20) DEFAULT 'pending',
    approved_by BIGINT,
    approved_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Performance reviews table
CREATE TABLE hc_core.performance_reviews (
    review_id BIGSERIAL PRIMARY KEY,
    employee_id BIGINT NOT NULL,
    reviewer_id BIGINT NOT NULL,
    review_period_start DATE NOT NULL,
    review_period_end DATE NOT NULL,
    overall_rating DECIMAL(3,2),
    goals_achieved INTEGER,
    total_goals INTEGER,
    comments TEXT,
    status VARCHAR(20) DEFAULT 'draft',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ==================================================
-- DISTRIBUTE TABLES
-- ==================================================

-- Distribute tables across worker nodes
SELECT create_distributed_table('hc_core.employees', 'employee_id');
SELECT create_distributed_table('hc_core.departments', 'department_id');
SELECT create_distributed_table('hc_core.positions', 'position_id');
SELECT create_distributed_table('hc_core.attendance', 'employee_id');
SELECT create_distributed_table('hc_core.leave_requests', 'employee_id');
SELECT create_distributed_table('hc_core.performance_reviews', 'employee_id');

-- ==================================================
-- INDEXES
-- ==================================================

CREATE INDEX idx_employees_email ON hc_core.employees(email);
CREATE INDEX idx_employees_department ON hc_core.employees(department_id);
CREATE INDEX idx_employees_status ON hc_core.employees(status);
CREATE INDEX idx_attendance_date ON hc_core.attendance(employee_id, attendance_date);
CREATE INDEX idx_leave_requests_dates ON hc_core.leave_requests(employee_id, start_date, end_date);
CREATE INDEX idx_performance_reviews_period ON hc_core.performance_reviews(employee_id, review_period_start);

-- ==================================================
-- SAMPLE DATA
-- ==================================================

-- Insert sample departments
INSERT INTO hc_core.departments (department_code, department_name, description, budget) VALUES
('HR', 'Human Resources', 'Human Resources Department', 500000.00),
('IT', 'Information Technology', 'IT Department', 1000000.00),
('FIN', 'Finance', 'Finance Department', 750000.00),
('MKT', 'Marketing', 'Marketing Department', 600000.00),
('OPS', 'Operations', 'Operations Department', 800000.00);

-- Insert sample positions
INSERT INTO hc_core.positions (position_code, position_title, department_id, level_grade, min_salary, max_salary, description) VALUES
('HR001', 'HR Manager', 1, 'M1', 80000.00, 120000.00, 'Human Resources Manager'),
('IT001', 'Software Engineer', 2, 'E3', 60000.00, 90000.00, 'Software Engineer'),
('FIN001', 'Financial Analyst', 3, 'E2', 55000.00, 80000.00, 'Financial Analyst'),
('MKT001', 'Marketing Specialist', 4, 'E2', 50000.00, 75000.00, 'Marketing Specialist'),
('OPS001', 'Operations Coordinator', 5, 'E1', 45000.00, 65000.00, 'Operations Coordinator');

-- Insert sample employees
INSERT INTO hc_core.employees (employee_code, first_name, last_name, email, phone, hire_date, department_id, position_id, salary, status) VALUES
('EMP001', 'John', 'Doe', 'john.doe@company.com', '+1234567890', '2023-01-15', 1, 1, 100000.00, 'active'),
('EMP002', 'Jane', 'Smith', 'jane.smith@company.com', '+1234567891', '2023-02-01', 2, 2, 75000.00, 'active'),
('EMP003', 'Mike', 'Johnson', 'mike.johnson@company.com', '+1234567892', '2023-02-15', 3, 3, 65000.00, 'active'),
('EMP004', 'Sarah', 'Wilson', 'sarah.wilson@company.com', '+1234567893', '2023-03-01', 4, 4, 60000.00, 'active'),
('EMP005', 'David', 'Brown', 'david.brown@company.com', '+1234567894', '2023-03-15', 5, 5, 55000.00, 'active');

COMMENT ON DATABASE postgres IS 'Human Capital Management Database - Citus Distributed';
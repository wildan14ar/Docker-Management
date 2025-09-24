-- ==================================================
-- INIT SQL FOR CITUS COORDINATOR - DOC SERVICE
-- Document Management Database
-- ==================================================

-- Create extension for Citus
CREATE EXTENSION IF NOT EXISTS citus;

-- Add worker nodes to the cluster
SELECT citus_add_node('worker1_doc', 5432);
SELECT citus_add_node('worker2_doc', 5432);

-- ==================================================
-- DATABASE SCHEMA FOR DOC SERVICE
-- ==================================================

-- Create database schemas
CREATE SCHEMA IF NOT EXISTS doc_core;
CREATE SCHEMA IF NOT EXISTS doc_workflow;
CREATE SCHEMA IF NOT EXISTS doc_analytics;

-- ==================================================
-- CORE TABLES
-- ==================================================

-- Documents table
CREATE TABLE doc_core.documents (
    document_id BIGSERIAL PRIMARY KEY,
    document_code VARCHAR(50) UNIQUE NOT NULL,
    title VARCHAR(255) NOT NULL,
    description TEXT,
    document_type VARCHAR(50) NOT NULL,
    category_id BIGINT,
    file_path VARCHAR(500),
    file_name VARCHAR(255),
    file_size BIGINT,
    file_type VARCHAR(50),
    mime_type VARCHAR(100),
    version INTEGER DEFAULT 1,
    status VARCHAR(20) DEFAULT 'draft',
    created_by BIGINT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Document categories table
CREATE TABLE doc_core.categories (
    category_id BIGSERIAL PRIMARY KEY,
    category_code VARCHAR(20) UNIQUE NOT NULL,
    category_name VARCHAR(100) NOT NULL,
    parent_category_id BIGINT,
    description TEXT,
    sort_order INTEGER DEFAULT 0,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Document versions table
CREATE TABLE doc_core.document_versions (
    version_id BIGSERIAL PRIMARY KEY,
    document_id BIGINT NOT NULL,
    version_number INTEGER NOT NULL,
    file_path VARCHAR(500),
    file_name VARCHAR(255),
    file_size BIGINT,
    change_notes TEXT,
    created_by BIGINT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Document access permissions table
CREATE TABLE doc_core.document_permissions (
    permission_id BIGSERIAL PRIMARY KEY,
    document_id BIGINT NOT NULL,
    user_id BIGINT,
    role_id BIGINT,
    permission_type VARCHAR(20) NOT NULL, -- read, write, delete, admin
    granted_by BIGINT NOT NULL,
    granted_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    expires_at TIMESTAMP,
    is_active BOOLEAN DEFAULT TRUE
);

-- Document workflow table
CREATE TABLE doc_workflow.workflows (
    workflow_id BIGSERIAL PRIMARY KEY,
    workflow_name VARCHAR(100) NOT NULL,
    workflow_type VARCHAR(50) NOT NULL,
    description TEXT,
    steps_json TEXT,
    is_active BOOLEAN DEFAULT TRUE,
    created_by BIGINT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Document workflow instances table
CREATE TABLE doc_workflow.workflow_instances (
    instance_id BIGSERIAL PRIMARY KEY,
    document_id BIGINT NOT NULL,
    workflow_id BIGINT NOT NULL,
    current_step INTEGER DEFAULT 1,
    status VARCHAR(20) DEFAULT 'pending',
    started_by BIGINT NOT NULL,
    started_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    completed_at TIMESTAMP,
    notes TEXT
);

-- Document comments/reviews table
CREATE TABLE doc_core.document_comments (
    comment_id BIGSERIAL PRIMARY KEY,
    document_id BIGINT NOT NULL,
    parent_comment_id BIGINT,
    user_id BIGINT NOT NULL,
    comment_text TEXT NOT NULL,
    comment_type VARCHAR(20) DEFAULT 'comment', -- comment, review, approval
    status VARCHAR(20) DEFAULT 'active',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Document tags table
CREATE TABLE doc_core.document_tags (
    tag_id BIGSERIAL PRIMARY KEY,
    document_id BIGINT NOT NULL,
    tag_name VARCHAR(50) NOT NULL,
    created_by BIGINT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ==================================================
-- DISTRIBUTE TABLES
-- ==================================================

-- Distribute tables across worker nodes
SELECT create_distributed_table('doc_core.documents', 'document_id');
SELECT create_distributed_table('doc_core.categories', 'category_id');
SELECT create_distributed_table('doc_core.document_versions', 'document_id');
SELECT create_distributed_table('doc_core.document_permissions', 'document_id');
SELECT create_distributed_table('doc_workflow.workflows', 'workflow_id');
SELECT create_distributed_table('doc_workflow.workflow_instances', 'document_id');
SELECT create_distributed_table('doc_core.document_comments', 'document_id');
SELECT create_distributed_table('doc_core.document_tags', 'document_id');

-- ==================================================
-- INDEXES
-- ==================================================

CREATE INDEX idx_documents_type ON doc_core.documents(document_type);
CREATE INDEX idx_documents_status ON doc_core.documents(status);
CREATE INDEX idx_documents_created_by ON doc_core.documents(created_by);
CREATE INDEX idx_documents_category ON doc_core.documents(category_id);
CREATE INDEX idx_document_versions_doc ON doc_core.document_versions(document_id, version_number);
CREATE INDEX idx_document_permissions_doc ON doc_core.document_permissions(document_id, user_id);
CREATE INDEX idx_workflow_instances_status ON doc_workflow.workflow_instances(document_id, status);
CREATE INDEX idx_document_comments_doc ON doc_core.document_comments(document_id, created_at);
CREATE INDEX idx_document_tags_name ON doc_core.document_tags(document_id, tag_name);

-- ==================================================
-- SAMPLE DATA
-- ==================================================

-- Insert sample categories
INSERT INTO doc_core.categories (category_code, category_name, description, sort_order) VALUES
('POLICY', 'Policies', 'Company policies and procedures', 1),
('CONTRACT', 'Contracts', 'Legal contracts and agreements', 2),
('TEMPLATE', 'Templates', 'Document templates', 3),
('REPORT', 'Reports', 'Business reports and analytics', 4),
('MANUAL', 'Manuals', 'User manuals and guides', 5);

-- Insert sample workflows
INSERT INTO doc_workflow.workflows (workflow_name, workflow_type, description, steps_json, created_by) VALUES
('Document Review', 'review', 'Standard document review process', '{"steps": [{"name": "Initial Review", "role": "reviewer"}, {"name": "Final Approval", "role": "approver"}]}', 1),
('Contract Approval', 'approval', 'Contract approval workflow', '{"steps": [{"name": "Legal Review", "role": "legal"}, {"name": "Management Approval", "role": "manager"}]}', 1),
('Policy Publication', 'publish', 'Policy publication workflow', '{"steps": [{"name": "Content Review", "role": "content_reviewer"}, {"name": "Compliance Check", "role": "compliance"}, {"name": "Publish", "role": "publisher"}]}', 1);

-- Insert sample documents
INSERT INTO doc_core.documents (document_code, title, description, document_type, category_id, file_name, file_type, mime_type, status, created_by) VALUES
('DOC001', 'Employee Handbook', 'Company employee handbook and policies', 'handbook', 1, 'employee_handbook_v1.pdf', 'pdf', 'application/pdf', 'published', 1),
('DOC002', 'Software License Agreement', 'Standard software license agreement template', 'template', 2, 'software_license_template.docx', 'docx', 'application/vnd.openxmlformats-officedocument.wordprocessingml.document', 'draft', 1),
('DOC003', 'Monthly Sales Report', 'Monthly sales performance report template', 'template', 4, 'monthly_sales_report.xlsx', 'xlsx', 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet', 'active', 1),
('DOC004', 'User Manual', 'System user manual and guide', 'manual', 5, 'system_user_manual.pdf', 'pdf', 'application/pdf', 'published', 1),
('DOC005', 'Data Privacy Policy', 'Company data privacy and protection policy', 'policy', 1, 'data_privacy_policy.pdf', 'pdf', 'application/pdf', 'review', 1);

-- Insert sample document permissions
INSERT INTO doc_core.document_permissions (document_id, user_id, permission_type, granted_by) VALUES
(1, 1, 'admin', 1),
(1, 2, 'read', 1),
(2, 1, 'write', 1),
(3, 1, 'write', 1),
(4, 2, 'read', 1),
(5, 1, 'admin', 1);

-- Insert sample tags
INSERT INTO doc_core.document_tags (document_id, tag_name, created_by) VALUES
(1, 'hr', 1),
(1, 'policy', 1),
(2, 'legal', 1),
(2, 'template', 1),
(3, 'sales', 1),
(3, 'report', 1),
(4, 'manual', 1),
(4, 'guide', 1),
(5, 'privacy', 1),
(5, 'compliance', 1);

COMMENT ON DATABASE postgres IS 'Document Management System Database - Citus Distributed';
-- ==================================================
-- INIT SQL FOR CITUS COORDINATOR - DOC SERVICE
-- Document Management Database
-- ==================================================

-- Create extension for Citus
CREATE EXTENSION IF NOT EXISTS citus;

-- Add worker nodes to the cluster
SELECT citus_add_node('worker1-doc', 5432);
SELECT citus_add_node('worker2-doc', 5432);

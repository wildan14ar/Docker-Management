-- ==================================================
-- INIT SQL FOR CITUS COORDINATOR - DOC SERVICE
-- Document Management Database
-- ==================================================

-- Create extension for Citus
CREATE EXTENSION IF NOT EXISTS citus;

-- Add worker nodes to the cluster
SELECT citus_add_node('worker-node1', 5432);
SELECT citus_add_node('worker-node2', 5432);
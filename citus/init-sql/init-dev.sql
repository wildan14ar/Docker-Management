-- ==================================================
-- INIT SQL FOR CITUS COORDINATOR - DEV SERVICE
-- Dev Management Database
-- ==================================================

-- Create extension for Citus
CREATE EXTENSION IF NOT EXISTS citus;

-- Add worker nodes to the cluster
SELECT citus_add_node('worker1-dev', 5432);
SELECT citus_add_node('worker2-dev', 5432);

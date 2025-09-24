-- ==================================================
-- INIT SQL FOR CITUS COORDINATOR - HC SERVICE
-- Human Capital Management Database
-- ==================================================

-- Create extension for Citus
CREATE EXTENSION IF NOT EXISTS citus;

-- Add worker nodes to the cluster
SELECT citus_add_node('worker1-hc', 5432);
SELECT citus_add_node('worker2-hc', 5432);

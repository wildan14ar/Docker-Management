# Citus Distributed PostgreSQL Setup

## Overview
Setup Citus cluster dengan 5 service yang berbeda, masing-masing dengan coordinator dan 2 worker nodes:

1. **HC (Human Capital)** - Port 5431
2. **DOC (Document Management)** - Port 5432
3. **FINANCE (Financial Management)** - Port 5433
4. **RISK (Risk Management)** - Port 5434
5. **MARKET (Market Data)** - Port 5435

## Architecture
- **PgPool**: Load balancer dan connection pooler (Port 9999)
- **Coordinators**: 5 coordinator nodes untuk setiap service
- **Workers**: 10 worker nodes (2 per service)

## Database Schemas

### HC Service (Human Capital Management)
- `hc_core`: Core HR tables (employees, departments, positions)
- `hc_reports`: Reporting tables
- `hc_analytics`: Analytics tables

**Key Tables:**
- `employees`: Employee information
- `departments`: Department structure
- `positions`: Job positions
- `attendance`: Attendance tracking
- `leave_requests`: Leave management
- `performance_reviews`: Performance evaluations

### DOC Service (Document Management)
- `doc_core`: Core document tables
- `doc_workflow`: Workflow management
- `doc_analytics`: Document analytics

**Key Tables:**
- `documents`: Document metadata
- `categories`: Document categories
- `document_versions`: Version control
- `document_permissions`: Access control
- `workflows`: Workflow definitions
- `workflow_instances`: Workflow executions
- `document_comments`: Reviews and comments

### FINANCE Service (Financial Management)
- `finance_core`: Core financial tables
- `finance_accounting`: Accounting tables
- `finance_reporting`: Financial reporting

**Key Tables:**
- `chart_of_accounts`: Chart of accounts
- `general_ledger`: General ledger entries
- `transactions`: Financial transactions
- `budgets`: Budget management
- `invoices`: Invoice management
- `payments`: Payment tracking
- `financial_periods`: Financial periods

### RISK Service (Risk Management)
- `risk_core`: Core risk tables
- `risk_assessment`: Risk assessment tables
- `risk_monitoring`: Risk monitoring tables

**Key Tables:**
- `risk_registers`: Risk registry
- `risk_categories`: Risk categories
- `assessments`: Risk assessments
- `risk_controls`: Risk controls
- `control_testing`: Control testing
- `incidents`: Risk incidents
- `mitigation_plans`: Risk mitigation

### MARKET Service (Market Data)
- `market_core`: Core market tables
- `market_data`: Market data tables
- `market_analytics`: Market analytics tables

**Key Tables:**
- `instruments`: Financial instruments
- `exchanges`: Stock exchanges
- `price_history`: Historical prices
- `real_time_quotes`: Real-time data
- `indices`: Market indices
- `economic_indicators`: Economic data
- `portfolios`: Portfolio management
- `market_news`: Market news

## Quick Start

### 1. Environment Setup
```bash
# Copy environment file
cp .env.example .env

# Edit environment variables
POSTGRES_USER=postgres
POSTGRES_PASSWORD=ppgpass
```

### 2. Start Services
```bash
# Start all services
docker-compose up -d

# Check status
docker-compose ps
```

### 3. Connect to Services

#### Via PgPool (Recommended)
```bash
# Connect through load balancer
psql -h localhost -p 9999 -U postgres
```

#### Direct Connection to Coordinators
```bash
# HC Service
psql -h localhost -p 5431 -U postgres

# DOC Service
psql -h localhost -p 5432 -U postgres

# FINANCE Service
psql -h localhost -p 5433 -U postgres

# RISK Service
psql -h localhost -p 5434 -U postgres

# MARKET Service
psql -h localhost -p 5435 -U postgres
```

## Data Distribution

All tables are distributed across worker nodes based on primary keys or logical distribution columns:

- **HC**: Distributed by `employee_id`
- **DOC**: Distributed by `document_id`
- **FINANCE**: Distributed by `account_id`, `transaction_id`, etc.
- **RISK**: Distributed by `risk_id`
- **MARKET**: Distributed by `instrument_id`, `portfolio_id`, etc.

## Sample Queries

### Check Cluster Status
```sql
-- Check worker nodes
SELECT * FROM citus_get_active_worker_nodes();

-- Check distributed tables
SELECT * FROM citus_tables;

-- Check shard distribution
SELECT table_name, shard_count FROM citus_shards;
```

### Performance Monitoring
```sql
-- Check query statistics
SELECT * FROM citus_stat_statements;

-- Check worker node stats
SELECT * FROM citus_worker_stat_activity;
```

## Management Commands

### Scale Workers
```sql
-- Add new worker node
SELECT citus_add_node('new_worker_host', 5432);

-- Remove worker node
SELECT citus_remove_node('worker_host', 5432);

-- Rebalance shards
SELECT citus_rebalance_start();
```

### Monitoring
```bash
# View logs
docker-compose logs -f coor_hc
docker-compose logs -f pgpool

# Monitor performance
docker stats
```

## Backup and Recovery

### Backup
```bash
# Backup specific service
pg_dump -h localhost -p 5431 -U postgres postgres > hc_backup.sql

# Backup through PgPool
pg_dump -h localhost -p 9999 -U postgres postgres > full_backup.sql
```

### Recovery
```bash
# Restore to specific service
psql -h localhost -p 5431 -U postgres postgres < hc_backup.sql
```

## Troubleshooting

### Common Issues
1. **Connection refused**: Check if containers are running
2. **Worker nodes not responding**: Restart worker containers
3. **Data not distributed**: Verify table distribution settings

### Useful Commands
```bash
# Restart specific service
docker-compose restart coor_hc worker1_hc worker2_hc

# View container logs
docker-compose logs coor_hc

# Connect to container shell
docker-compose exec coor_hc bash
```

## Security Notes

- Change default passwords in production
- Configure proper network security
- Enable SSL/TLS for connections
- Implement proper user access controls
- Regular security updates

## Performance Tuning

### PostgreSQL Configuration
- Adjust `shared_buffers`
- Tune `work_mem`
- Configure `max_connections`
- Optimize `checkpoint_segments`

### Citus Configuration
- Monitor shard distribution
- Balance worker loads
- Optimize distributed queries
- Regular shard rebalancing

## Monitoring and Alerting

Recommended monitoring:
- Connection counts
- Query performance
- Disk usage
- Memory utilization
- Network I/O
- Replication lag
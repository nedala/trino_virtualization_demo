# DBeaver Connection Guide for Trino Demo

## Prerequisites
- DBeaver installed (https://dbeaver.io/download/)
- Trino demo environment running (`./setup_demo.sh`)
- Docker services healthy

---

## Step-by-Step Connection Setup

### 1. Launch DBeaver and Create New Connection

1. Open DBeaver
2. Click **Database** → **New Database Connection** (or click the + icon in the Database Navigator)
3. In the search box, type **Trino** and select it
4. Click **Next**

### 2. Configure Connection Parameters

#### Main Settings Tab:
```
Host: localhost
Port: 8080
Database: minio (default catalog)
User: demo_user
Password: (leave empty)
```

#### Advanced Settings:
- **Default schema:** default
- **Client tags:** demo
- **Timezone:** UTC (or your local timezone)

### 3. Test Connection

1. Click **Test Connection** 
2. You should see: "Connected successfully"
3. If successful, click **Finish**

---

## Exploring the Federated Catalogs

### View Available Catalogs
Once connected, expand the connection tree to see:

```
localhost:8080
├── minio (Hive on MinIO)
│   └── default
│       ├── customers
│       ├── orders  
│       ├── products
│       └── stock_ticks (Kafka view)
├── sqlserver (SQL Server)
│   └── master
│       └── demo
│           ├── customerloyalty
│           └── fxrates
├── kafka (Streaming)
│   └── default
│       └── test (raw topic)
└── uploads (Postgres)
    └── assistant
```

### Browse Data
- Double-click any table to view data
- Right-click table → **View Data** for grid view
- Use **SQL Editor** for custom queries

---

## Demo Queries for DBeaver

### 1. Basic Catalog Exploration
```sql
-- Show all catalogs
SHOW CATALOGS;

-- Show tables in MinIO
SHOW TABLES FROM minio.default;

-- Show tables in SQL Server
SHOW TABLES FROM sqlserver.master.demo;
```

### 2. Sample Data from Each Source
```sql
-- Hive/MinIO data
SELECT * FROM minio.default.customers LIMIT 5;
SELECT * FROM minio.default.orders LIMIT 5;

-- SQL Server data  
SELECT * FROM sqlserver.master.demo.customerloyalty;

-- Kafka raw data
SELECT _partition_id, _partition_offset, 
       CAST(_message AS VARCHAR) AS message
FROM kafka.default.test 
LIMIT 5;
```

### 3. The Magic - Federated Query
```sql
-- Join across Hive + SQL Server
SELECT
    c.customer_name,
    c.country,
    l.loyalty_tier,
    COUNT(DISTINCT o.order_id) AS orders,
    SUM(o.quantity * o.price_usd) AS revenue_usd
FROM minio.default.orders o
JOIN minio.default.customers c ON o.customer_id = c.customer_id
LEFT JOIN sqlserver.master.demo.customerloyalty l ON l.customer_id = c.customer_id
GROUP BY c.customer_name, c.country, l.loyalty_tier
ORDER BY revenue_usd DESC;
```

### 4. Full Federated with Kafka
```sql
-- Complete cross-system query
SELECT
    c.customer_name,
    l.loyalty_tier,
    p.sector,
    SUM(o.quantity * o.price_usd) AS order_value,
    MAX(t.price) AS latest_stock_price
FROM minio.default.orders o
JOIN minio.default.customers c ON o.customer_id = c.customer_id
LEFT JOIN sqlserver.master.demo.customerloyalty l ON l.customer_id = c.customer_id
LEFT JOIN minio.default.products p ON p.symbol = o.symbol
LEFT JOIN minio.default.stock_ticks t ON t.symbol = o.symbol
     AND t.event_ts BETWEEN o.order_ts - INTERVAL '5' MINUTE
                        AND o.order_ts + INTERVAL '5' MINUTE
GROUP BY c.customer_name, l.loyalty_tier, p.sector
ORDER BY order_value DESC;
```

---

## DBeaver Features for Demo

### 1. Execution Plan
- Write a query in SQL Editor
- Press **Explain Plan** (F10) or click the plan icon
- Shows how Trino optimizes and pushes down operations

### 2. Data Export
- Right-click results → **Export Result Set**
- Export to CSV, Excel, JSON for further analysis

### 3. Query History
- **SQL** → **SQL History** (Ctrl+Alt+H)
- Reuse previous queries during demo

### 4. ER Diagrams
- Right-click database → **ER Diagram**
- Visualize table relationships across catalogs

---

## Troubleshooting

### Connection Issues

**Error: "Connection refused"**
```bash
# Check if Trino is running
docker-compose ps trino

# Restart Trino if needed
docker-compose restart trino
```

**Error: "Authentication failed"**
- Ensure user is `demo_user`
- Password should be empty
- Check Trino logs: `docker logs trino`

### Query Issues

**Error: "Catalog not found"**
```sql
-- Verify catalogs are available
SHOW CATALOGS;
```

**Error: "Table not found"**
```sql
-- Check table names
SHOW TABLES FROM minio.default;
SHOW TABLES FROM sqlserver.master.demo;
```

**Slow Queries**
- Check if Kafka data is being generated (run KafkaMockStream.ipynb)
- Verify data is loaded in Hive tables (run PrepareDataTables.ipynb)

---

## Demo Tips for DBeaver

### Before the Demo
1. Test all connections and queries
2. Save frequently used queries as snippets
3. Set up workspace layout (SQL Editor + Results)

### During the Demo
1. Use **Auto-complete** (Ctrl+Space) to show table/column names
2. Demonstrate **Explain Plan** to show Trino optimization
3. Use **Results Grid** features (sorting, filtering)
4. Show **Multiple Results** tabs for different queries

### Impressive Features to Highlight
- **Cross-catalog joins** in single query
- **Sub-second response** times
- **Auto-discovery** of data sources
- **SQL standard compliance** (no proprietary syntax)

---

## Quick Reference Card

### Connection Details
```
Host: localhost
Port: 8080
User: demo_user
Driver: Trino
```

### Key Catalogs
- `minio.default.*` - Hive tables on MinIO
- `sqlserver.master.demo.*` - SQL Server demo data
- `kafka.default.test` - Kafka streaming topic

### Must-Run Queries
1. `SHOW CATALOGS;` - Show federation
2. Federated join query - Show cross-system analytics
3. Performance test query - Show speed

---

## Ready to Demo!

With DBeaver connected to Trino, you can now:
- Browse all data sources from one interface
- Run cross-system federated queries
- Demonstrate sub-second analytics performance
- Show enterprise-ready SQL tooling

**You're ready to showcase the power of Trino federation!**
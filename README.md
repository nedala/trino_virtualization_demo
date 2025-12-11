# Trino Demo: Federated Analytics

## Quick Start


This demo shows how Trino can query multiple data systems at once, with no ETL and fast performance.


### Quick Setup
docker-compose up -d

Run:
```bash
./setup_demo.sh
```

Or manually start services:
```bash
docker-compose up -d
```

### Manual Steps

Start services:
```bash
docker-compose up -d
```

Open Jupyter in your browser at http://localhost:8888

## Demo Architecture


Trino connects to MinIO (Hive), SQL Server, and Kafka, allowing you to run queries across all of them at once.

## Demo Flow

### 1. Data Preparation (2 minutes)

Run: SparkStart_Streamlined.ipynb


What it does:
- Initializes Spark with MinIO/S3A configuration
- Loads airports data from web to MinIO/Hive
- Loads customers data to PostgreSQL (demopg.customers)
- Loads orders and products to MinIO/Hive (default.orders, default.products)
- Includes PyHive utilities and error handling


Data Distribution:
| System      | Data      | Location             | Purpose               |
|-------------|-----------|----------------------|-----------------------|
| PostgreSQL  | Customers | postgresdb.customers | Operational CRM       |
| MinIO/Hive  | Orders    | default.orders       | Historical analytics  |
| MinIO/Hive  | Products  | default.products     | Product catalog       |
| MinIO/Hive  | Airports  | default.airports     | Geographic data       |

### 2. Stream Generation (1 minute)

Run: KafkaMockStream_Streamlined.ipynb


What it does:
- Generates realistic stock price data
- Publishes to Kafka topic 'test'
- Includes 8 major stock symbols
- Real-time price movements (-2% to +2%)

### 3. Main Demo (10 minutes)

Run: TrinoFederatedDemo_Streamlined.ipynb


What it demonstrates:

Example query:
```sql
SELECT
    c.customer_name,
    l.loyalty_tier,
    p.sector,
    SUM(o.quantity * o.price_usd) AS order_value_usd,
    MAX(t.price) AS latest_stock_price
FROM minio.default.orders o
JOIN minio.default.customers c ON o.customer_id = c.customer_id
LEFT JOIN sqlserver.master.demo.customerloyalty l ON l.customer_id = c.customer_id
LEFT JOIN minio.default.products p ON p.symbol = o.symbol
LEFT JOIN minio.default.stock_ticks t ON t.symbol = o.symbol
 AND t.event_ts BETWEEN o.order_ts - INTERVAL '5' MINUTE
                    AND o.order_ts + INTERVAL '5' MINUTE
GROUP BY c.customer_name, l.loyalty_tier, p.sector
ORDER BY order_value_usd DESC;
```

Key Demonstrations:
- Multi-system federation: Single SQL across 4 systems
- Fast performance: Complex queries in under 1 second
- Real-time analytics: Historical and live stream data
- OLAP capabilities: Advanced aggregations and cube analysis
- Visualizations: Plotly charts and dashboards


4. SQL Client Demo (Optional)
Tool: DBeaver or any SQL client
Connection: localhost:8080 (user: demo_user)

Example queries:
```sql
SHOW CATALOGS;
```

```sql
SELECT c.customer_name, l.loyalty_tier, COUNT(o.order_id) as orders
FROM minio.default.customers c
JOIN minio.default.orders o ON c.customer_id = o.customer_id
LEFT JOIN sqlserver.master.demo.customerloyalty l ON l.customer_id = c.customer_id
GROUP BY c.customer_name, l.loyalty_tier;
```

## Access Points

| Service        | URL                      | Credentials           | Purpose              |
|---------------|--------------------------|-----------------------|----------------------|
| Jupyter       | http://localhost:8888    | -                     | Notebooks & demo     |
| Trino UI      | http://localhost:8080    | -                     | Query interface      |
| MinIO Console | http://localhost:9001    | minioadmin/minioadmin | Object storage       |
| Superset      | http://localhost:8090    | admin/admin           | BI dashboards        |


## Key Benefits

Performance:
- Query response: under 1 second
- Real-time latency: under 100ms
- Memory efficiency: Columnar processing
- Scalability: Distributed execution

Business Value:
- No ETL: Query data where it lives
- Cost efficiency: Free and open source
- Time to insight: Hours to minutes
- Flexibility: Any data source, any format

Enterprise Use Cases:
- Financial services: Risk analytics across trading and CRM
- Retail: Customer 360 (transactions, loyalty, web)
- Manufacturing: IoT, ERP, supply chain
- Healthcare: Patient records, claims, monitoring


## Requirements

System:
- RAM: 8GB or more recommended
- CPU: 4 or more cores recommended
- Storage: 10GB free space
- OS: Linux, macOS, or Windows with WSL2

Software:
- Docker and Docker Compose
- Modern web browser
- Optional: DBeaver (SQL client)

Network:
- Ports 8080, 8888, 9000, 9001, 9092, 1433, 5432, 8090 available
- Internet connection for package installation

docker-compose logs trino
docker-compose logs jupyter
docker-compose down -v
docker-compose up -d

## Common Docker Commands

Restart all services:
```bash
docker-compose down && docker-compose up -d
```

Check logs:
```bash
docker-compose logs trino
docker-compose logs jupyter
```

Reset all data:
```bash
docker-compose down -v
docker-compose up -d
```

## Troubleshooting

Common Issues:
1. Services not ready: Wait 2-3 minutes, check 'docker-compose ps'
2. Connection refused: Verify port forwarding, check firewall
3. No Kafka data: Run KafkaMockStream_Streamlined.ipynb first
4. Slow queries: Check data preparation, run SparkStart_Streamlined.ipynb

Recovery Commands:


## Demo Management Scripts

Complete setup (first time or full reset):
```bash
./setup_demo.sh
```

Quick restart (services only):
```bash
./start_demo.sh
```

Clean restart (removes Trino data only):
```bash
./cleanup_demo.sh
```

Note: The cleanup_demo.sh script only removes Trino-specific volumes and containers, preserving other Docker data on your system. This makes it safe for development environments.
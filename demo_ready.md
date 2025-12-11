# Trino Demo Environment Ready!

## Environment Status
All services are running and healthy
Sample data is prepared
SQL Server demo data is loaded
Trino is ready for federated queries

## Access URLs
- **Jupyter Notebook:** http://localhost:8888
- **Trino Web UI:** http://localhost:8080
- **MinIO Console:** http://localhost:9001 (minioadmin/minioadmin)
- **Superset:** http://localhost:8090 (admin/admin)

## Demo Checklist
1. Open Jupyter at http://localhost:8888
2. Run 'PrepareDataTables_Streamlined.ipynb' to prepare Hive data
3. Run 'KafkaMockStream_Streamlined.ipynb' to start live streaming
4. Run 'TrinoFederatedDemo_Streamlined.ipynb' for the main demo
5. For SQL client demo, connect DBeaver to Trino (localhost:8080)

## Available Data Sources
- **MinIO/Hive:** customers, orders, products
- **SQL Server:** customerloyalty, fxrates  
- **Kafka:** stock_ticks (real-time stream)

## Ready to Demo!
Follow the demo_script.md for step-by-step presentation guidance.

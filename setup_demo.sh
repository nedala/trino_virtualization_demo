#!/bin/bash

# Trino Demo Setup Automation Script
# This script prepares the entire demo environment for a flawless presentation

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Status indicators
CHECK="[OK]"
CROSS="[ERROR]"
WARNING="[WARNING]"
INFO="[INFO]"

echo -e "${BLUE} Trino Demo Setup Automation${NC}"
echo "=================================="
echo

# Function to print status
print_status() {
    echo -e "${GREEN}${CHECK} $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}${WARNING} $1${NC}"
}

print_error() {
    echo -e "${RED}${CROSS} $1${NC}"
}

print_info() {
    echo -e "${BLUE}${INFO} $1${NC}"
}

# Check if Docker is running
check_docker() {
    print_info "Checking Docker installation..."
    if ! command -v docker &> /dev/null; then
        print_error "Docker is not installed or not in PATH"
        exit 1
    fi
    
    if ! docker info &> /dev/null; then
        print_error "Docker daemon is not running"
        exit 1
    fi
    
    print_status "Docker is running"
}

# Check if Docker Compose is available
check_docker_compose() {
    print_info "Checking Docker Compose..."
    if ! command -v docker-compose &> /dev/null && ! docker compose version &> /dev/null; then
        print_error "Docker Compose is not installed"
        exit 1
    fi
    print_status "Docker Compose is available"
}

# Stop any existing containers
cleanup_existing() {
    print_info "Cleaning up existing containers..."
    if docker-compose ps -q | grep -q .; then
        docker-compose down -v
        print_status "Existing containers stopped and removed"
    else
        print_status "No existing containers to clean up"
    fi
}

# Build and start containers
start_services() {
    print_info "Building and starting demo services..."
    docker-compose up -d --build
    
    print_status "Services started successfully"
}

# Wait for services to be healthy
wait_for_services() {
    print_info "Waiting for services to be healthy..."
    
    # Service health check commands
    declare -A services=(
        ["trino"]="docker exec trino trino --execute 'SELECT 1' &>/dev/null"
        ["jupyter"]="curl -f http://localhost:8888/api &>/dev/null"
        ["sqlserver"]="docker exec sqlserver /opt/mssql-tools/bin/sqlcmd -S localhost -U sa -P 'yourStrong(!)Password' -Q 'SELECT 1' &>/dev/null"
        ["kafka"]="docker exec kafka bash -c 'echo > /dev/tcp/kafka/9092' &>/dev/null"
        ["superset"]="curl -f http://localhost:8090/health &>/dev/null"
        ["minio"]="curl -f http://localhost:9000/minio/health/live &>/dev/null"
        ["postgres"]="docker exec postgresdb pg_isready &>/dev/null"
    )
    
    local max_attempts=30
    local attempt=1
    
    while [ $attempt -le $max_attempts ]; do
        local unhealthy=()
        
        for service in "${!services[@]}"; do
            if ! eval "${services[$service]}" 2>/dev/null; then
                unhealthy+=("$service")
            fi
        done
        
        if [ ${#unhealthy[@]} -eq 0 ]; then
            print_status "All services are healthy!"
            return 0
        fi
        
        print_warning "Unhealthy services: ${unhealthy[*]} (attempt $attempt/$max_attempts)"
        echo -n "."
        sleep 5
        ((attempt++))
    done
    
    print_error "Services did not become healthy within expected time"
    return 1
}

# Prepare sample data
prepare_data() {
    print_info "Checking sample data..."
    
    # Verify data files exist
    if [ -f "data/customers.csv" ] && [ -f "data/orders.csv" ] && [ -f "data/products.csv" ]; then
        print_status "Sample data files ready"
    else
        print_error "Missing required data files. Please ensure customers.csv, orders.csv, and products.csv exist in data/ directory"
        exit 1
    fi
}

# Setup SQL Server demo data
setup_sqlserver_data() {
    print_info "Setting up SQL Server demo data..."
    
    # Wait a bit more for SQL Server to be fully ready
    sleep 10
    
    # Create demo schema and tables
    docker exec sqlserver /opt/mssql-tools/bin/sqlcmd -S localhost -U sa -P 'yourStrong(!)Password' -Q "
    CREATE SCHEMA demo AUTHORIZATION dbo;
    " 2>/dev/null || true
    
    docker exec sqlserver /opt/mssql-tools/bin/sqlcmd -S localhost -U sa -P 'yourStrong(!)Password' -Q "
    CREATE TABLE demo.CustomerLoyalty (
      customer_id INT PRIMARY KEY,
      loyalty_tier VARCHAR(32),
      discount_pct DECIMAL(5,2)
    );
    " 2>/dev/null || true
    
    docker exec sqlserver /opt/mssql-tools/bin/sqlcmd -S localhost -U sa -P 'yourStrong(!)Password' -Q "
    INSERT INTO demo.CustomerLoyalty VALUES
    (1, 'PLATINUM', 10.0),
    (2, 'GOLD', 5.0),
    (3, 'SILVER', 2.5),
    (4, 'PLATINUM', 10.0),
    (5, 'PLATINUM', 10.0),
    (6, 'GOLD', 5.0),
    (7, 'SILVER', 2.5),
    (8, 'BRONZE', 0.0),
    (9, 'GOLD', 5.0),
    (10, 'PLATINUM', 10.0);
    " 2>/dev/null || true
    
    docker exec sqlserver /opt/mssql-tools/bin/sqlcmd -S localhost -U sa -P 'yourStrong(!)Password' -Q "
    CREATE TABLE demo.FxRates (
      currency_code CHAR(3) PRIMARY KEY,
      usd_rate DECIMAL(12,6)
    );
    " 2>/dev/null || true
    
    docker exec sqlserver /opt/mssql-tools/bin/sqlcmd -S localhost -U sa -P 'yourStrong(!)Password' -Q "
    INSERT INTO demo.FxRates VALUES
    ('USD', 1.0),
    ('CAD', 0.75),
    ('GBP', 1.25),
    ('EUR', 1.10),
    ('JPY', 0.0067);
    " 2>/dev/null || true
    
    print_status "SQL Server demo data created"
}

# Start Kafka data generation
start_kafka_stream() {
    print_info "Kafka stream can be started by running 'KafkaMockStream_Streamlined.ipynb' in Jupyter"
    print_status "Kafka producer notebook ready"
}

# Verify Trino connectivity
verify_trino() {
    print_info "Verifying Trino connectivity..."
    
    # Test basic connectivity
    if docker exec trino trino --execute "SHOW CATALOGS" &>/dev/null; then
        print_status "Trino is responding to queries"
    else
        print_error "Trino is not responding"
        return 1
    fi
    
    # Test catalog access
    catalogs=$(docker exec trino trino --execute "SHOW CATALOGS" --output-format csv | tail -n +2)
    if echo "$catalogs" | grep -q "minio\|sqlserver\|kafka"; then
        print_status "Trino catalogs are accessible"
    else
        print_warning "Some catalogs may not be fully ready yet"
    fi
}

# Create demo summary
create_demo_summary() {
    print_info "Creating demo summary..."
    
    cat > demo_ready.md << 'EOF'
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
EOF

    print_status "Demo summary created: demo_ready.md"
}

# Main execution
main() {
    echo -e "${BLUE}Starting Trino Demo Setup...${NC}"
    echo
    
    check_docker
    check_docker_compose
    cleanup_existing
    prepare_data
    start_services
    
    echo
    print_info "Waiting for services to initialize..."
    wait_for_services
    
    setup_sqlserver_data
    verify_trino
    create_demo_summary
    
    echo
    echo -e "${GREEN} Demo setup completed successfully!${NC}"
    echo
    echo -e "${BLUE}Next steps:${NC}"
    echo "1. Open http://localhost:8888 for Jupyter notebooks"
    echo "2. Run 'PrepareDataTables_Streamlined.ipynb' to prepare Hive data"
    echo "3. Run 'KafkaMockStream_Streamlined.ipynb' to start live streaming"
    echo "4. Run 'TrinoFederatedDemo_Streamlined.ipynb' for the main demo"
    echo "5. Follow demo_script.md for presentation guidance"
    echo
    echo -e "${YELLOW}Note: Streamlined notebooks use built-in jupyter-pyspark with MinIO/S3A support${NC}"
}

# Run main function
main "$@"
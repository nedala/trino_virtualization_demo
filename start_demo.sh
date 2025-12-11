#!/bin/bash

# Trino Demo Start Script
# Starts services without cleanup for quick demo restart

set -e

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

echo -e "${BLUE}Trino Demo Start${NC}"
echo "=================================="

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

# Start containers only
start_containers() {
    print_info "Starting Trino demo services..."
    if docker-compose up -d; then
        print_status "Services started successfully"
        print_info "Access URLs:"
        echo "  Jupyter: http://localhost:8888"
        echo "  Trino UI: http://localhost:8080"
        echo "  MinIO Console: http://localhost:9001"
        echo "  Superset: http://localhost:8090"
    else
        print_error "Failed to start services"
        exit 1
    fi
}

# Wait for services to be healthy
wait_for_services() {
    print_info "Waiting for services to be healthy..."
    
    local max_attempts=30
    local attempt=1
    
    while [ $attempt -le $max_attempts ]; do
        # Check if Trino is responding
        if docker exec trino trino --execute 'SELECT 1' &>/dev/null 2>&1; then
            print_status "Trino is healthy"
            break
        fi
        
        if [ $attempt -eq $max_attempts ]; then
            print_warning "Services may not be fully ready, but continuing..."
            break
        fi
        
        sleep 2
        ((attempt++))
    done
}

# Main start function
main() {
    echo -e "${BLUE}Starting Trino demo services...${NC}"
    echo
    
    start_containers
    wait_for_services
    
    echo
    echo -e "${GREEN}Demo services started successfully!${NC}"
    echo
    echo -e "${BLUE}Next steps:${NC}"
    echo "1. Open http://localhost:8888 for Jupyter"
    echo "2. Run 'SparkStart_Streamlined.ipynb' to prepare data"
    echo "3. Run 'KafkaMockStream_Streamlined.ipynb' to start streaming"
    echo "4. Run 'TrinoFederatedDemo_Streamlined.ipynb' for main demo"
    echo "5. Use './cleanup_demo.sh' for clean restart"
}

# Run main function
main "$@"
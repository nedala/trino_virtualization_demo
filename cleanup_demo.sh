#!/bin/bash

# Trino Demo Cleanup Script
# Wipes Docker containers and volumes for a clean start

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

echo -e "${BLUE}Trino Demo Cleanup${NC}"
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

# Stop and remove containers
cleanup_containers() {
    print_info "Stopping and removing containers..."
    if docker-compose ps -q | grep -q .; then
        docker-compose down -v --remove-orphans
        print_status "Containers stopped and removed"
    else
    print_info "No containers running"
    fi
}

# Remove Trino-related Docker volumes only
cleanup_volumes() {
    print_info "Removing Trino demo volumes..."
    # Remove only Trino-related named volumes
    docker volume rm trino_data trino_warehouse trino_minio_data 2>/dev/null || true
    print_status "Trino volumes removed"
}

# Remove unused Docker images
cleanup_images() {
    print_info "Removing unused Docker images..."
    docker image prune -f
    print_status "Unused Docker images removed"
}

# Clean up temporary files
cleanup_temp_files() {
    print_info "Cleaning up temporary files..."
    
    # Remove any temporary data files
    rm -f data/temp_* 2>/dev/null || true
    
    # Clean up any checkpoint files
    rm -f *.checkpoint 2>/dev/null || true
    
    # Remove any log files
    rm -f *.log 2>/dev/null || true
    
    print_status "Temporary files cleaned"
}

# Reset network
reset_network() {
    print_info "Resetting Docker network..."
    docker network prune -f
    print_status "Docker network reset"
}

# Main cleanup function
main() {
    echo -e "${BLUE}Starting Trino demo cleanup...${NC}"
    echo
    
    cleanup_containers
    cleanup_volumes
    cleanup_images
    cleanup_temp_files
    reset_network
    
    echo
    echo -e "${GREEN}Demo cleanup completed successfully!${NC}"
    echo
    echo -e "${BLUE}Next steps:${NC}"
    echo "1. Run './setup_demo.sh' to start fresh"
    echo "2. Run './start_demo.sh' to start services only"
    echo "3. Open http://localhost:8888 for Jupyter"
    echo
}

# Run main function
main "$@"
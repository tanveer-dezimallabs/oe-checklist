#!/bin/bash

# OptiExacta Health Check Script
# This script monitors key services and storage permissions

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_header() {
    echo -e "${BLUE}================================${NC}"
    echo -e "${BLUE}   OptiExacta Health Monitor    ${NC}"
    echo -e "${BLUE}================================${NC}"
    echo ""
}

print_status() {
    echo -e "${BLUE}[STATUS]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

check_docker_services() {
    print_status "Checking Docker services..."
    
    # Check upload service
    if sudo docker ps --format "{{.Names}}\t{{.Status}}" | grep -q "oe-oe-upload-1.*Up"; then
        print_success "Upload service is running"
    else
        print_error "Upload service is not running properly"
        return 1
    fi
    
    # Check legacy service
    if sudo docker ps --format "{{.Names}}\t{{.Status}}" | grep -q "oe-oe-legacy-1.*Up.*healthy"; then
        print_success "Legacy service is running and healthy"
    else
        print_warning "Legacy service may not be healthy"
    fi
    
    # Check stream worker
    if sudo docker ps --format "{{.Names}}\t{{.Status}}" | grep -q "oe-oe-stream-worker-1.*Up"; then
        print_success "Stream worker is running"
    else
        print_error "Stream worker is not running properly"
        return 1
    fi
    
    # Check total running containers
    local running_count=$(sudo docker ps --format "{{.Names}}" | grep -c "oe-")
    print_status "Total running containers: $running_count"
}

check_storage_permissions() {
    print_status "Checking storage permissions..."
    
    # Check upload directory
    if [ -d "/opt/oe/data/oe-upload/uploads" ]; then
        local perms=$(stat -c "%a" /opt/oe/data/oe-upload/uploads 2>/dev/null)
        if [ "$perms" = "777" ]; then
            print_success "Upload directory permissions are correct (777)"
        else
            print_warning "Upload directory permissions are $perms (should be 777)"
            print_status "Fixing upload directory permissions..."
            if sudo chmod -R 777 /opt/oe/data/oe-upload/uploads/; then
                print_success "Upload directory permissions fixed"
            else
                print_error "Failed to fix upload directory permissions"
                return 1
            fi
        fi
    else
        print_error "Upload directory does not exist"
        return 1
    fi
    
    # Check tarantool directories
    for i in {1..16}; do
        local shard_dir="/opt/oe/data/oe-tarantool-shard$i"
        if [ ! -d "$shard_dir" ]; then
            print_warning "Tarantool shard $i directory missing"
            print_status "Creating shard $i directory..."
            if sudo mkdir -p "$shard_dir" && sudo chown -R 999:999 "$shard_dir"; then
                print_success "Created and configured shard $i directory"
            else
                print_error "Failed to create shard $i directory"
                return 1
            fi
        fi
    done
}

check_face_detection_status() {
    print_status "Checking face detection status..."
    
    # Check recent stream worker logs for successful posts
    local recent_posts=$(sudo docker logs --tail=20 oe-oe-stream-worker-1 2>/dev/null | grep -c "objects_posted")
    if [ "$recent_posts" -gt 0 ]; then
        print_success "Stream worker is processing faces"
        # Get the latest stats
        local latest_stats=$(sudo docker logs --tail=10 oe-oe-stream-worker-1 2>/dev/null | grep "objects_posted" | tail -1)
        if [ -n "$latest_stats" ]; then
            # Extract just the objects_posted count
            local posted_count=$(echo "$latest_stats" | grep -o "objects_posted:[0-9]*" | cut -d: -f2)
            if [ -n "$posted_count" ] && [ "$posted_count" -gt 0 ]; then
                print_success "Total faces posted: $posted_count"
            fi
        fi
    else
        print_warning "No recent face processing activity detected"
    fi
    
    # Check upload server recent activity for HTTP 201 responses
    local upload_success=$(sudo docker logs --tail=10 oe-oe-upload-1 2>/dev/null | grep -c "201")
    if [ "$upload_success" -gt 0 ]; then
        print_success "Upload server is storing faces successfully ($upload_success recent uploads)"
    else
        print_warning "No recent successful uploads detected"
    fi
}

check_api_endpoints() {
    print_status "Checking API endpoints..."
    
    # Check if legacy service responds
    local legacy_response=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8000/ 2>/dev/null || echo "000")
    if [ "$legacy_response" = "200" ] || [ "$legacy_response" = "302" ]; then
        print_success "Legacy API is responding (HTTP $legacy_response)"
    else
        print_warning "Legacy API may not be responding properly (HTTP $legacy_response)"
    fi
}

main() {
    print_header
    
    local overall_status=0
    
    check_docker_services || overall_status=1
    echo ""
    
    check_storage_permissions || overall_status=1
    echo ""
    
    check_face_detection_status
    echo ""
    
    check_api_endpoints
    echo ""
    
    if [ $overall_status -eq 0 ]; then
        print_success "All critical systems are healthy!"
    else
        print_warning "Some issues were detected and may have been fixed"
    fi
    
    echo ""
    echo "Health check completed at $(date)"
}

# Run the health check
main "$@"

#!/bin/bash

set -e

# Function to print status messages
print_status() {
    echo "[INFO] $1"
}

print_success() {
    echo "[SUCCESS] $1"
}

print_error() {
    echo "[ERROR] $1"
}

print_warning() {
    echo "[WARNING] $1"
}

# 1. Rename config directory if it exists
if [ -d "/opt/oe/configs/findface-sf-api" ]; then
    if [ -d "/opt/oe/configs/oe-api" ]; then
        print_warning "Both directories exist"
        print_status "Merging"
        cp -r /opt/oe/configs/findface-sf-api/* /opt/oe/configs/oe-api/ 2>/dev/null || true
        rm -rf /opt/oe/configs/findface-sf-api
        print_success "Merged and removed directory"
    else
        mv /opt/oe/configs/findface-sf-api /opt/oe/configs/oe-api
        print_success "Config directory configured!"
    fi
elif [ -d "/opt/oe/configs/oe-api" ]; then
    print_success "oe-api directory already exists"
else
    print_error "No directory found!"
    exit 1
fi

# 1a. Handle config file naming
if [ -d "/opt/oe/configs/oe-api/oe-api.yaml" ]; then
    print_status "Removing existing oe-api.yaml directory (should be a file)"
    rm -rf /opt/oe/configs/oe-api/oe-api.yaml
fi

if [ -f "/opt/oe/configs/oe-api/findface-sf-api.yaml" ]; then
    print_status "Moving to oe-api.yaml"
    mv /opt/oe/configs/oe-api/findface-sf-api.yaml /opt/oe/configs/oe-api/oe-api.yaml
    print_success "Config file renamed"
elif [ -f "/opt/oe/configs/oe-api/oe-api.yaml" ]; then
    print_success "oe-api.yaml already exists"
else
    print_warning "No SF API config file found"
fi

# 2. Update docker-compose.yaml: service name, depends_on, and config paths
print_status "Updating docker-compose.yaml references"
if [ -f "/opt/oe/docker-compose.yaml" ]; then
    # Check if changes are needed
    if grep -q "findface-sf-api" /opt/oe/docker-compose.yaml; then
        print_status "Found references, updating..."
        # Create backup
        cp /opt/oe/docker-compose.yaml /opt/oe/docker-compose.yaml.backup.$(date +%Y%m%d_%H%M%S)
        
        # Update service references
        sed -i 's/findface-sf-api/oe-api/g' /opt/oe/docker-compose.yaml
        sed -i 's/configs\/findface-sf-api/configs\/oe-api/g' /opt/oe/docker-compose.yaml
        print_success "docker-compose.yaml updated"
    else
        print_success "docker-compose.yaml already updated, no changes needed"
    fi
else
    print_error "docker-compose.yaml not found!"
    exit 1
fi

print_success "process completed"

echo "Note: Docker services will be restarted by the main script"

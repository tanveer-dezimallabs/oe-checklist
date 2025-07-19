#!/bin/bash

# Script to rename ntech to optiexacta in docker-compose.yaml
# This makes the change persistent across docker-compose down/up

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

print_status "Starting ntech to optiexacta rebranding process..."

# Check if docker-compose.yaml exists
if [ ! -f "/opt/oe/docker-compose.yaml" ]; then
    print_error "docker-compose.yaml not found at /opt/oe/"
    exit 1
fi

# Create backup with timestamp
backup_file="/opt/oe/docker-compose.yaml.backup.rebrand.$(date +%Y%m%d_%H%M%S)"
print_status "Creating backup: $backup_file"
cp /opt/oe/docker-compose.yaml "$backup_file"
print_success "Backup created"

# Replace ntech with optiexacta in docker-compose.yaml
print_status "Replacing 'ntech' with 'optiexacta' in docker-compose.yaml..."

# Replace in image names
sed -i 's|docker\.int\.ntl/ntech/|docker.int.ntl/optiexacta/|g' /opt/oe/docker-compose.yaml

# Replace in environment variables (like RABBITMQ_DEFAULT_USER)
sed -i 's/RABBITMQ_DEFAULT_USER: ntech/RABBITMQ_DEFAULT_USER: optiexacta/g' /opt/oe/docker-compose.yaml

# Replace in connection strings and URLs that contain ntech
sed -i 's/:ntech:/:optiexacta:/g' /opt/oe/docker-compose.yaml
sed -i 's|//ntech:|//optiexacta:|g' /opt/oe/docker-compose.yaml

print_success "Replacements completed"

# Validate docker-compose file syntax
print_status "Validating docker-compose.yaml syntax..."
if docker-compose -f /opt/oe/docker-compose.yaml config > /dev/null 2>&1; then
    print_success "Docker Compose file is valid"
else
    print_error "Docker Compose file validation failed!"
    print_error "Restoring backup..."
    cp "$backup_file" /opt/oe/docker-compose.yaml
    exit 1
fi

# Show what changed
print_status "Changes made:"
echo "✓ Replaced docker.int.ntl/ntech/ with docker.int.ntl/optiexacta/ in image references"
echo "✓ Replaced RABBITMQ_DEFAULT_USER from ntech to optiexacta"
echo "✓ Updated connection strings containing ntech"

print_warning "IMPORTANT NOTES:"
echo "1. This change affects Docker image paths - make sure optiexacta images exist or are accessible"
echo "2. RabbitMQ credentials have been updated - this will create new user 'optiexacta'"
echo "3. Database connection strings have been updated"
echo "4. You need to restart Docker services for changes to take effect"

print_success "Rebranding completed successfully!"
echo ""
echo "Next steps:"
echo "1. Run: sudo docker-compose down"
echo "2. Run: sudo docker-compose up -d"
echo "3. Or use: sudo ./run_all_scripts.sh (if you want to run all scripts again)"

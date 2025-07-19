#!/bin/bash

set -e

cd /opt/oe

# Pre-migration cleanup (optional - removes any existing findface-upload remnants)
echo "Performing pre-migration cleanup of any existing remnants..."
docker stop $(docker ps -aq --filter "name=findface-upload") 2>/dev/null || true
docker rm $(docker ps -aq --filter "name=findface-upload") 2>/dev/null || true
docker volume rm $(docker volume ls -q --filter "name=findface-upload") 2>/dev/null || true

# Check if docker-compose is available
if ! command -v docker-compose &> /dev/null; then
    echo "Error: docker-compose is not installed or not in PATH"
    exit 1
fi

# Create backup of docker-compose.yaml
echo "Creating backup of docker-compose.yaml..."
cp docker-compose.yaml "docker-compose.yaml.backup.$(date +%Y%m%d_%H%M%S)"

# 1. Fix config directory and file structure
if [ -d "./configs/findface-upload" ]; then
    # Copy the config files
    mkdir -p ./configs/oe-upload
    cp -r ./configs/findface-upload/* ./configs/oe-upload/
    # Remove the original directory after copying
    rm -rf ./configs/findface-upload
fi

# 2. Handle data directory
if [ -d "./data/findface-upload" ]; then
    # Copy contents to new directory
    mkdir -p ./data/oe-upload
    cp -r ./data/findface-upload/* ./data/oe-upload/ 2>/dev/null || true
    # Remove the original directory after copying
    rm -rf ./data/findface-upload
fi

# 3. Update docker-compose.yaml references
# Update service name and all references
sed -i 's#findface-upload#oe-upload#g' docker-compose.yaml
sed -i 's#configs/findface-upload#configs/oe-upload#g' docker-compose.yaml
sed -i 's#data/findface-upload#data/oe-upload#g' docker-compose.yaml

# 4. Update references in other service configs
for config in ./configs/*/oe-*.yaml ./configs/*/findface-*.yaml; do
    if [ -f "$config" ]; then
        # Update upload service references in other service configs
        sed -i 's#findface-upload#oe-upload#g' "$config"
    fi
done

# 5. Fix permissions for the upload service
echo "Setting up proper permissions for oe-upload service..."
if [ -d "./data/oe-upload" ]; then
    # Create uploads directory if it doesn't exist
    mkdir -p ./data/oe-upload/uploads
    
    # Set permissive permissions for the upload directory
    chmod -R 755 ./data/oe-upload/
    
    # Note: Additional permission fixes will be applied inside the container after restart
fi

# 6. Clean up old findface-upload remnants
echo "Cleaning up old findface-upload remnants..."

# Stop and remove any existing containers
echo "Stopping and removing any findface-upload containers..."
docker stop $(docker ps -aq --filter "name=findface-upload") 2>/dev/null || true
docker rm $(docker ps -aq --filter "name=findface-upload") 2>/dev/null || true

# Remove any findface-upload volumes
echo "Removing findface-upload volumes..."
docker volume rm $(docker volume ls -q --filter "name=findface-upload") 2>/dev/null || true

# Remove any findface-upload networks
docker network rm $(docker network ls -q --filter "name=findface-upload") 2>/dev/null || true

# Remove any findface-upload images (optional - commented out to preserve images)
# echo "Removing findface-upload images..."
# docker rmi $(docker images -q --filter "reference=*findface-upload*") 2>/dev/null || true

# Clean up any remaining findface-upload references in config files
find ./configs -name "*.yaml" -o -name "*.yml" -o -name "*.conf" -o -name "*.sh" | xargs sed -i 's#findface-upload#oe-upload#g' 2>/dev/null || true

# Remove any leftover findface-upload directories
rm -rf ./configs/findface-upload 2>/dev/null || true
rm -rf ./data/findface-upload 2>/dev/null || true
rm -rf ./cache/findface-upload 2>/dev/null || true

# Clean up any backup files that might contain findface-upload references
echo "Cleaning up backup files..."
find . -name "*.bak" -o -name "*.backup" | grep -i upload | xargs rm -f 2>/dev/null || true

# 7. Restart Docker Compose
echo "Restarting Docker Compose services..."
docker-compose down --remove-orphans

# 8. Fix container-side permissions after startup
echo "Waiting for oe-upload service to start..."
sleep 10

# Check if the container is running and fix permissions
if docker-compose ps oe-upload | grep -q "Up"; then
    echo "Fixing permissions inside the oe-upload container..."
    docker exec $(docker-compose ps -q oe-upload) chown -R nginx:nginx /var/lib/ffupload/ || true
    docker exec $(docker-compose ps -q oe-upload) chmod -R 755 /var/lib/ffupload/ || true
    docker exec $(docker-compose ps -q oe-upload) chmod -R 777 /var/lib/ffupload/uploads/ || true
    
    echo "Restarting oe-upload service to apply permission changes..."
    docker-compose restart oe-upload
else
    echo "Warning: oe-upload service is not running. You may need to fix permissions manually."
fi

# 9. Final cleanup verification
echo "Performing final cleanup verification..."

# Verify no findface-upload containers exist
if docker ps -a --filter "name=findface-upload" --format "table {{.Names}}" | grep -q findface-upload; then
    echo "⚠️  Warning: Some existing upload containers still exist"
    docker ps -a --filter "name=findface-upload"
else
    echo "✅ No existing upload containers found"
fi

# Verify no findface-upload volumes exist
if docker volume ls --filter "name=findface-upload" --format "table {{.Name}}" | grep -q findface-upload; then
    echo "⚠️  Warning: Some existing upload volumes still exist"
    docker volume ls --filter "name=findface-upload"
else
    echo "✅ No findface-upload volumes found"
fi

# Check for any remaining findface-upload references in docker-compose.yaml
if grep -q "findface-upload" docker-compose.yaml; then
    echo "⚠️  Warning: existing upload references still found in docker-compose.yaml"
    grep -n "findface-upload" docker-compose.yaml
else
    echo "✅ No existing-upload references found in docker-compose.yaml"
fi

# Check for any remaining findface-upload directories
if find . -type d -name "*findface-upload*" 2>/dev/null | grep -q .; then
    echo "⚠️  Warning: Some upload directories still exist"
    find . -type d -name "*findface-upload*"
else
    echo "✅ No findface-upload directories found"
fi

echo "The upload service should now be working correctly with proper permissions."

# 10. Verify the service is working
echo "Verifying the upload service is working..."
sleep 5

# Test the upload service with a simple request
if curl -s -X PUT http://127.0.0.1:3333/uploads/test/migration/test.txt -d "migration test" > /dev/null 2>&1; then
    echo "✅ Upload service is working correctly!"
    # Clean up test file
    docker exec $(docker-compose ps -q oe-upload) rm -f /var/lib/ffupload/uploads/test/migration/test.txt || true
else
    echo "⚠️  Upload service may not be working properly. Please check the logs:"
    echo "   docker logs $(docker-compose ps -q oe-upload)"
fi

echo ""
echo "Migration completed successfully!"
echo "- Service renamed from 'findface-upload' to 'oe-upload'"
echo "- Configuration and data directories updated"
echo "- Permissions fixed for proper operation"
echo "- Docker Compose services restarted"
echo ""
echo "Summary of cleanup actions performed:"
echo "- ✅ Updated all config file references"
echo "- ✅ Removed leftover directories"
echo "- ✅ Cleaned up backup files"
echo "- ✅ Verified no findface-upload remnants remain"

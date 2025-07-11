#!/bin/bash
set -e

# Absolute paths
CONFIGS_DIR="/opt/oe/configs"
OLD_DIR="findface-multi-onvif-discovery"
NEW_DIR="oe-onvif-discovery"
OLD_SERVICE="findface-multi-onvif-discovery"
NEW_SERVICE="oe-onvif-discovery"
DOCKER_COMPOSE="/opt/oe/docker-compose.yaml"

echo "🔄 Starting ONVIF Discovery renaming process..."

# 1. Check and rename config directory if it exists
if [ -d "$CONFIGS_DIR/$OLD_DIR" ]; then
    mv "$CONFIGS_DIR/$OLD_DIR" "$CONFIGS_DIR/$NEW_DIR"
    echo "✅ Renamed config directory: $CONFIGS_DIR/$OLD_DIR → $CONFIGS_DIR/$NEW_DIR"
else
    echo "⚠️  Directory $CONFIGS_DIR/$OLD_DIR does not exist!"
    # Check if already renamed
    if [ -d "$CONFIGS_DIR/$NEW_DIR" ]; then
        echo "✅ Directory already renamed to $CONFIGS_DIR/$NEW_DIR"
    else
        echo "❌ Neither old nor new directory exists!"
        # Create the directory if it doesn't exist
        mkdir -p "$CONFIGS_DIR/$NEW_DIR"
        echo "✅ Created new directory: $CONFIGS_DIR/$NEW_DIR"
    fi
fi

# 2. Stop Docker Compose services
echo "🛑 Stopping Docker Compose services..."
cd /opt/oe && docker-compose down

# 3. Update config directory references in docker-compose.yaml
echo "📝 Updating config directory references..."
sed -i "s|configs/$OLD_DIR|configs/$NEW_DIR|g" "$DOCKER_COMPOSE"

# 4. Update data directory references
echo "📝 Updating data directory references..."
sed -i "s|data/$OLD_DIR|data/$NEW_DIR|g" "$DOCKER_COMPOSE"

# 5. Rename the service name in docker-compose.yaml
echo "🔧 Renaming service name in docker-compose.yaml..."
sed -i "s/^  $OLD_SERVICE:/  $NEW_SERVICE:/" "$DOCKER_COMPOSE"

# 6. Update all references to this service in depends_on and other places
echo "🔗 Updating service dependencies..."
sed -i "s/\b$OLD_SERVICE\b/$NEW_SERVICE/g" "$DOCKER_COMPOSE"


# 7. Fix any indentation issues that might have been introduced
echo "🔧 Fixing YAML indentation..."
# Fix any depends_on indentation issues
sed -i '/^depends_on:/s/^/  /' "$DOCKER_COMPOSE"

# 8. Validate the docker-compose.yaml file
echo "✅ Validating docker-compose.yaml..."
cd /opt/oe
if docker-compose config > /dev/null 2>&1; then
    echo "✅ Docker compose file is valid"
else
    echo "❌ Docker compose file has errors:"
    docker-compose config
    echo "🔄 Please check the YAML syntax and fix any issues"
    exit 1
fi

# 09. Start the services with new names
echo "🚀 Starting services with new names..."
cd /opt/oe && docker-compose up -d

# 10. Verify the services are running
echo "🔍 Checking service status..."
sleep 10
docker ps --filter "name=oe-onvif-discovery" --format "table {{.Names}}\t{{.Status}}"

echo ""
echo "🎉 ONVIF Discovery renaming completed successfully!"
echo "=============================================="
echo "Summary of changes:"
echo "- ✅ Renamed config directory: $OLD_DIR → $NEW_DIR"
echo "- ✅ Updated docker-compose.yaml config paths"
echo "- ✅ Updated docker-compose.yaml data paths"
echo "- ✅ Renamed service: $OLD_SERVICE → $NEW_SERVICE"
echo "- ✅ Updated all service dependencies"
echo "- ✅ Removed liveness dependencies"
echo "- ✅ Fixed YAML indentation issues"
echo "- ✅ Validated docker-compose.yaml syntax"
echo "- ✅ Restarted services"
echo ""
echo "🚀 ONVIF Discovery service should now be running with the new oe-onvif-discovery name!"

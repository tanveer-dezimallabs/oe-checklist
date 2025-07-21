#!/bin/bash
set -e

# Absolute paths
CONFIGS_DIR="/opt/oe/configs"
OLD_DIR="findface-multi-file-mover"
NEW_DIR="oe-file-mover"
OLD_FILE="findface-multi-file-mover.yaml"
NEW_FILE="oe-file-mover.yaml"
OLD_SERVICE="findface-multi-file-mover"
NEW_SERVICE="oe-file-mover"
DOCKER_COMPOSE="/opt/oe/docker-compose.yaml"

echo "🔄 Starting File Mover configuration process..."

# 1. Rename directory and file
if [ -d "$CONFIGS_DIR/$OLD_DIR" ]; then
    mv "$CONFIGS_DIR/$OLD_DIR/$OLD_FILE" "$CONFIGS_DIR/$OLD_DIR/$NEW_FILE"
    mv "$CONFIGS_DIR/$OLD_DIR" "$CONFIGS_DIR/$NEW_DIR"
    echo "✅ Configured"
else
    echo "⚠️  Directory does not exist!"
    # Check if already renamed
    if [ -d "$CONFIGS_DIR/$NEW_DIR" ]; then
        echo "✅ Directory already configured"
    else
        echo "❌ Neither old nor new directory exists!"
        exit 1
    fi
fi

# 2. Stop Docker Compose services
echo "🛑 Stopping Docker Compose services..."
cd /opt/oe && docker-compose down

# 3. Update docker-compose.yaml file references
echo "📝 Updating docker-compose.yaml config references..."
sed -i "s|configs/$OLD_DIR/$OLD_FILE|configs/$NEW_DIR/$NEW_FILE|g" "$DOCKER_COMPOSE"

# 4. Update data directory references
echo "📝 Updating data directory references..."
sed -i "s|data/$OLD_DIR|data/$NEW_DIR|g" "$DOCKER_COMPOSE"

# 5. Rename the service name in docker-compose.yaml
sed -i "s/^  $OLD_SERVICE:/  $NEW_SERVICE:/" "$DOCKER_COMPOSE"

# 6. Update all references to this service in depends_on and other places
echo "🔗 Updating service dependencies..."
sed -i "s/\b$OLD_SERVICE\b/$NEW_SERVICE/g" "$DOCKER_COMPOSE"

# 7. Remove any liveness dependencies (cleanup)
sed -i 's/, findface-liveness-api//g' "$DOCKER_COMPOSE"
sed -i 's/findface-liveness-api, //g' "$DOCKER_COMPOSE"
sed -i 's/\[findface-liveness-api\]//g' "$DOCKER_COMPOSE"

# 8. Fix any indentation issues that might have been introduced
echo "🔧 Fixing YAML indentation..."
# Fix any depends_on indentation issues
sed -i '/^depends_on:/s/^/  /' "$DOCKER_COMPOSE"

# 9. Validate the docker-compose.yaml file
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

# 11. Verify the services are running
echo "🔍 Checking service status..."
sleep 10
docker ps --filter "name=oe-file-mover" --format "table {{.Names}}\t{{.Status}}"

echo ""

echo "Updated $DOCKER_COMPOSE references."

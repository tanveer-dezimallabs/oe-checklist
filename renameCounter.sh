#!/bin/bash
set -e

# Absolute paths
CONFIGS_DIR="/opt/oe/configs"
OLD_DIR="findface-counter"
NEW_DIR="oe-counter"
OLD_FILE="findface-counter.yaml"
NEW_FILE="oe-counter.yaml"
OLD_SERVICE="findface-counter"
NEW_SERVICE="oe-counter"
DOCKER_COMPOSE="/opt/oe/docker-compose.yaml"

# 1. Rename directory and file
if [ -d "$CONFIGS_DIR/$OLD_DIR" ]; then
    mv "$CONFIGS_DIR/$OLD_DIR/$OLD_FILE" "$CONFIGS_DIR/$OLD_DIR/$NEW_FILE"
    mv "$CONFIGS_DIR/$OLD_DIR" "$CONFIGS_DIR/$NEW_DIR"
    echo "✅ configured"
else
    echo "⚠️  Directory $CONFIGS_DIR/$OLD_DIR does not exist!"
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

# 3. Update docker-compose.yaml config references
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

# 7. Fix any indentation issues that might have been introduced
echo "🔧 Fixing YAML indentation..."
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

# 10. Verify the services are running
echo "🔍 Checking service status..."
sleep 10
docker ps --filter "name=oe-counter" --format "table {{.Names}}\t{{.Status}}"

echo ""

echo "Updated $DOCKER_COMPOSE references."

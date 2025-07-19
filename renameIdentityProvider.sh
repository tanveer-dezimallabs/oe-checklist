#!/bin/bash
set -e

# Absolute paths
CONFIGS_DIR="/opt/oe/configs"
OLD_DIR="findface-multi-identity-provider"
NEW_DIR="oe-identity-provider"
OLD_FILE="findface-multi-identity-provider.py"
NEW_FILE="oe-identity-provider.py"
DOCKER_COMPOSE="/opt/oe/docker-compose.yaml"

# 1. Rename directory and file
if [ -d "$CONFIGS_DIR/$OLD_DIR" ]; then
    mv "$CONFIGS_DIR/$OLD_DIR/$OLD_FILE" "$CONFIGS_DIR/$OLD_DIR/$NEW_FILE"
    mv "$CONFIGS_DIR/$OLD_DIR" "$CONFIGS_DIR/$NEW_DIR"
    echo "✅ Done"
else
    echo "⚠️  Directory does not exist!"
    # Check if already renamed
    if [ -d "$CONFIGS_DIR/$NEW_DIR" ]; then
    else
        echo "❌ Neither old nor new directory exists!"
        exit 1
    fi
fi

# 2. Stop Docker Compose services
echo "🛑 Stopping Docker Compose services..."
cd /opt/oe && docker-compose down

# 3. Update docker-compose.yaml file references
echo "📝 Updating docker-compose.yaml references..."
sed -i "s|configs/$OLD_DIR/$OLD_FILE|configs/$NEW_DIR/$NEW_FILE|g" "$DOCKER_COMPOSE"

# 4. Rename the service names in docker-compose.yaml
sed -i 's/^  findface-multi-identity-provider:/  oe-identity-provider:/' "$DOCKER_COMPOSE"
sed -i 's/^  findface-multi-identity-provider-migrate:/  oe-identity-provider-migrate:/' "$DOCKER_COMPOSE"

# 5. Update all references to these services in depends_on and other places
echo "🔗 Updating service dependencies..."
sed -i 's/findface-multi-identity-provider-migrate/oe-identity-provider-migrate/g' "$DOCKER_COMPOSE"
sed -i 's/findface-multi-identity-provider/oe-identity-provider/g' "$DOCKER_COMPOSE"

# 7. Fix any indentation issues that might have been introduced
echo "🔧 Fixing YAML indentation..."
# Fix the depends_on indentation issue we encountered
sed -i '/oe-identity-provider-migrate:/,/environment:/ {
  s/^depends_on:/  depends_on:/
}' "$DOCKER_COMPOSE"

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
docker ps --filter "name=oe-identity-provider" --format "table {{.Names}}\t{{.Status}}"

echo ""

echo "Updated $DOCKER_COMPOSE references."

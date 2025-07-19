#!/bin/bash
set -e

COMPOSE_FILE="/opt/oe/docker-compose.yaml"
ALARM_CONFIG_DIR="/opt/oe/configs/alarm-app"
ALARM_NGINX_CONF="/opt/oe/configs/alarm-app/nginx-site.conf"

echo "🔄 Starting alarm services removal..."

# 1. Remove alarm services from docker-compose.yaml
echo "📝 Removing alarm services from docker-compose.yaml..."

# First, let's create a backup
cp "$COMPOSE_FILE" "${COMPOSE_FILE}.backup.$(date +%Y%m%d_%H%M%S)"
echo "✅ Created backup: ${COMPOSE_FILE}.backup.$(date +%Y%m%d_%H%M%S)"

# Function to remove a service block
remove_service() {
    local service_name="$1"
    echo "🗑️  Removing service: $service_name"
    awk -v service="$service_name" '
    /^  / && $0 ~ "^  " service ":$" {
        skip = 1
        next
    }
    /^  [a-zA-Z0-9_-]+:$/ && skip {
        skip = 0
    }
    /^[a-zA-Z0-9_-]+:$/ && skip {
        skip = 0
    }
    !skip {
        print
    }
    ' "$COMPOSE_FILE" > "${COMPOSE_FILE}.tmp" && mv "${COMPOSE_FILE}.tmp" "$COMPOSE_FILE"
}

# Remove all alarm-related services
remove_service "service_alarmer"
remove_service "service_notifier_ws"
remove_service "service_notifier_tg"
remove_service "alarm-app"

# 2. Remove alarm services from any depends_on arrays
echo "🔗 Removing alarm services from depends_on arrays..."
sed -i 's/service_alarmer, //g; s/, service_alarmer//g; s/\[service_alarmer\]//g' "$COMPOSE_FILE"
sed -i 's/service_notifier_ws, //g; s/, service_notifier_ws//g; s/\[service_notifier_ws\]//g' "$COMPOSE_FILE"
sed -i 's/service_notifier_tg, //g; s/, service_notifier_tg//g; s/\[service_notifier_tg\]//g' "$COMPOSE_FILE"
sed -i 's/alarm-app, //g; s/, alarm-app//g; s/\[alarm-app\]//g' "$COMPOSE_FILE"

# Remove standalone depends_on entries
sed -i 's/depends_on: \[service_alarmer\]//g' "$COMPOSE_FILE"
sed -i 's/depends_on: \[service_notifier_ws\]//g' "$COMPOSE_FILE"
sed -i 's/depends_on: \[service_notifier_tg\]//g' "$COMPOSE_FILE"
sed -i 's/depends_on: \[alarm-app\]//g' "$COMPOSE_FILE"

# 3. Remove alarm configuration files
echo "🗂️  Removing alarm configuration files..."
if [ -d "$ALARM_CONFIG_DIR" ]; then
    rm -rf "$ALARM_CONFIG_DIR"
    echo "✅ Removed directory: $ALARM_CONFIG_DIR"
else
    echo "ℹ️  Directory $ALARM_CONFIG_DIR does not exist"
fi

# 4. Clean up any malformed lines
echo "🧹 Cleaning up malformed YAML..."
sed -i '/^  :$/d' "$COMPOSE_FILE"
sed -i '/^  *:$/d' "$COMPOSE_FILE"
sed -i '/^[[:space:]]*$/d' "$COMPOSE_FILE"

# 5. Stop and remove existing alarm containers
echo "🛑 Stopping and removing alarm-related containers..."
docker stop $(docker ps -aq --filter "name=alarm") 2>/dev/null || echo "ℹ️  No alarm containers to stop"
docker rm $(docker ps -aq --filter "name=alarm") 2>/dev/null || echo "ℹ️  No alarm containers to remove"
docker stop $(docker ps -aq --filter "name=service_alarmer") 2>/dev/null || echo "ℹ️  No service_alarmer containers to stop"
docker rm $(docker ps -aq --filter "name=service_alarmer") 2>/dev/null || echo "ℹ️  No service_alarmer containers to remove"
docker stop $(docker ps -aq --filter "name=service_notifier") 2>/dev/null || echo "ℹ️  No service_notifier containers to stop"
docker rm $(docker ps -aq --filter "name=service_notifier") 2>/dev/null || echo "ℹ️  No service_notifier containers to remove"

# 6. Clean up alarm references in config files
echo "🧽 Cleaning up alarm references in configuration files..."
find /opt/oe/configs -name "*.py" -type f -exec grep -l "alarm" {} \; 2>/dev/null | while read -r file; do
    echo "📝 Cleaning alarm references in: $file"
    sed -i "s/'alarm_app_url':.*$/# 'alarm_app_url': removed - alarm app deleted/g" "$file" 2>/dev/null || true
    sed -i "s/alarm_app_url.*$/# alarm_app_url removed - alarm app deleted/g" "$file" 2>/dev/null || true
done

# 7. Remove alarm-related environment variables
echo "🌍 Removing alarm-related environment variables..."
find /opt/oe/configs -name "*.yaml" -o -name "*.yml" -type f -exec grep -l -i "alarm\|notifier" {} \; 2>/dev/null | while read -r file; do
    echo "📝 Cleaning alarm env vars in: $file"
    sed -i '/alarm/Id' "$file" 2>/dev/null || true
    sed -i '/notifier/Id' "$file" 2>/dev/null || true
done

# 8. Validate the docker-compose.yaml file
echo "✅ Validating docker-compose.yaml file..."
cd /opt/oe
if docker-compose config > /dev/null 2>&1; then
    echo "✅ Docker Compose file is valid"
else
    echo "❌ Docker Compose file has errors:"
    docker-compose config
    echo "🔄 Restoring from backup..."
    BACKUP_FILE=$(ls -t "${COMPOSE_FILE}.backup."* 2>/dev/null | head -1)
    if [ -n "$BACKUP_FILE" ]; then
        cp "$BACKUP_FILE" "$COMPOSE_FILE"
        echo "✅ Restored from $BACKUP_FILE"
    fi
    exit 1
fi

# 10. Verify removal
echo "🔍 Verifying alarm services removal..."
ALARM_CONTAINERS=$(docker ps --filter "name=alarm" --format "table {{.Names}}" 2>/dev/null | grep -v NAMES || true)
ALARMER_CONTAINERS=$(docker ps --filter "name=service_alarmer" --format "table {{.Names}}" 2>/dev/null | grep -v NAMES || true)
NOTIFIER_CONTAINERS=$(docker ps --filter "name=service_notifier" --format "table {{.Names}}" 2>/dev/null | grep -v NAMES || true)

if [ -n "$ALARM_CONTAINERS" ]; then
    echo "⚠️  Warning: Some alarm containers still exist:"
    echo "$ALARM_CONTAINERS"
else
    echo "✅ No alarm containers found"
fi

if [ -n "$ALARMER_CONTAINERS" ]; then
    echo "⚠️  Warning: service_alarmer containers still exist:"
    echo "$ALARMER_CONTAINERS"
else
    echo "✅ No service_alarmer containers found"
fi

if [ -n "$NOTIFIER_CONTAINERS" ]; then
    echo "⚠️  Warning: service_notifier containers still exist:"
    echo "$NOTIFIER_CONTAINERS"
else
    echo "✅ No service_notifier containers found"
fi

echo ""
echo "🎉 Alarm services removal completed!"
echo "=============================================="
echo "✅ Removed services:"
echo "- service_alarmer (alarm processing service)"
echo "- service_notifier_ws (WebSocket notifier service)"
echo "- service_notifier_tg (Telegram notifier service)"
echo "- alarm-app (alarm monitoring web app)"
echo ""
echo "✅ Cleaned up:"
echo "- alarm-app configuration directory"
echo "- alarm_app_url references in config files"
echo "- alarm-related environment variables"
echo "- service dependencies"
echo "- Docker containers and images"
echo ""
echo "🚀 All alarm services have been successfully removed!"


#!/bin/bash
set -e

COMPOSE_FILE="docker-compose.yaml"
CONFIGS_DIR="./configs"

# Remove alarm-related services from docker-compose.yaml
sed -i '/alarm-app:/,/^  [a-zA-Z0-9_-]\+:/ {/^  [a-zA-Z0-9_-]\+:/!d; /^  [a-zA-Z0-9_-]\+:/b}; /alarm-app:/d' "$COMPOSE_FILE"
sed -i '/service_alarmer:/,/^  [a-zA-Z0-9_-]\+:/ {/^  [a-zA-Z0-9_-]\+:/!d; /^  [a-zA-Z0-9_-]\+:/b}; /service_alarmer:/d' "$COMPOSE_FILE"
sed -i '/service_notifier_ws:/,/^  [a-zA-Z0-9_-]\+:/ {/^  [a-zA-Z0-9_-]\+:/!d; /^  [a-zA-Z0-9_-]\+:/b}; /service_notifier_ws:/d' "$COMPOSE_FILE"
sed -i '/service_notifier_tg:/,/^  [a-zA-Z0-9_-]\+:/ {/^  [a-zA-Z0-9_-]\+:/!d; /^  [a-zA-Z0-9_-]\+:/b}; /service_notifier_tg:/d' "$COMPOSE_FILE"

# Remove alarm-app config directory if it exists
if [ -d "$CONFIGS_DIR/alarm-app" ]; then
    rm -rf "$CONFIGS_DIR/alarm-app"
    echo "Removed $CONFIGS_DIR/alarm-app"
fi

echo "Alarm-related services and configs removed from $COMPOSE_FILE."

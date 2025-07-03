#!/bin/bash
set -e

COMPOSE_FILE="/opt/oe/docker-compose.yaml"
LIVENESS_CONFIG_DIR="/opt/oe/configs/findface-liveness-api"
LIVENESS_YAML="/opt/oe/configs/findface-liveness-api/findface-liveness-api.yaml"

# 1. Remove findface-liveness-api service from docker-compose.yaml
sed -i '/findface-liveness-api:/,/^  [a-zA-Z0-9_-]\+:/ {/^  [a-zA-Z0-9_-]\+:/!d; /^  [a-zA-Z0-9_-]\+:/b}; /findface-liveness-api:/d' "$COMPOSE_FILE"

# 2. Remove findface-liveness-api from any depends_on arrays
sed -i 's/findface-liveness-api, //g; s/, findface-liveness-api//g; s/findface-liveness-api//g' "$COMPOSE_FILE"

# 3. Remove the liveness config directory and yaml file if they exist
if [ -d "$LIVENESS_CONFIG_DIR" ]; then
    rm -rf "$LIVENESS_CONFIG_DIR"
    echo "Removed directory: $LIVENESS_CONFIG_DIR"
fi

if [ -f "$LIVENESS_YAML" ]; then
    rm -f "$LIVENESS_YAML"
    echo "Removed file: $LIVENESS_YAML"
fi

echo "Liveness service, config directory, and yaml file have been removed from /opt/oe/configs."

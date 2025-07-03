#!/bin/bash
set -e

COMPOSE_FILE="docker-compose.yaml"
LEGACY_CONFIG="./configs/findface-multi-legacy/findface-multi-legacy.py"
COUNTER_CONFIG_DIR="./configs/findface-counter"

# 1. Remove findface-counter service from docker-compose.yaml
sed -i '/findface-counter:/,/^  [a-zA-Z0-9_-]\+:/ {/^  [a-zA-Z0-9_-]\+:/!d; /^  [a-zA-Z0-9_-]\+:/b}; /findface-counter:/d' "$COMPOSE_FILE"
# Remove findface-counter from any depends_on arrays
sed -i 's/findface-counter, //g; s/, findface-counter//g; s/findface-counter//g' "$COMPOSE_FILE"

# 2. Remove all counter-related config lines from findface-multi-legacy.py
sed -i '/COUNTER/d' "$LEGACY_CONFIG"
sed -i '/FFCOUNTER/d' "$LEGACY_CONFIG"
sed -i '/counter/d' "$LEGACY_CONFIG"
sed -i '/Counters/d' "$LEGACY_CONFIG"
sed -i '/COUNTERS_/d' "$LEGACY_CONFIG"
sed -i '/MAX_COUNTER_ERROR_RECORDS/d' "$LEGACY_CONFIG"

# 3. Remove the findface-counter config directory
if [ -d "$COUNTER_CONFIG_DIR" ]; then
    rm -rf "$COUNTER_CONFIG_DIR"
    echo "Removed $COUNTER_CONFIG_DIR"
fi

echo "Counter service and all related configs have been removed."

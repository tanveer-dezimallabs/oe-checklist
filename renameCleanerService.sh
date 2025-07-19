#!/bin/bash
set -e

DOCKER_COMPOSE="/opt/oe/docker-compose.yaml"
OLD_SERVICE="findface-multi-cleaner"
NEW_SERVICE="oe-cleaner"

# Rename the service and all references to it
sed -i "s/\b$OLD_SERVICE\b/$NEW_SERVICE/g" "$DOCKER_COMPOSE"

echo "Configured successfully"

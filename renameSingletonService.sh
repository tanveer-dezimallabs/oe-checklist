#!/bin/bash
set -e

DOCKER_COMPOSE="/opt/oe/docker-compose.yaml"
OLD_SERVICE="findface-multi-legacy-singleton-services"
NEW_SERVICE="oe-legacy-singleton-services"

# Rename the service and all references to it
sed -i "s/\b$OLD_SERVICE\b/$NEW_SERVICE/g" "$DOCKER_COMPOSE"

echo "Done successfully for Singleton"

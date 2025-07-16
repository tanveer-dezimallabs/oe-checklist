#!/bin/bash

set -e


# 1. Rename config directory if it exists
if [ -d "/opt/oe/configs/findface-sf-api" ]; then
    mv /opt/oe/configs/findface-sf-api /opt/oe/configs/oe-api
fi

# 1a. Remove oe-api.yaml directory if it exists, and move config file
if [ -d "/opt/oe/configs/oe-api/oe-api.yaml" ]; then
    rm -rf /opt/oe/configs/oe-api/oe-api.yaml
fi
if [ -f "/opt/oe/configs/oe-api/findface-sf-api.yaml" ]; then
    mv /opt/oe/configs/oe-api/findface-sf-api.yaml /opt/oe/configs/oe-api/oe-api.yaml
fi

# 2. Update docker-compose.yaml: service name, depends_on, and config paths
sed -i 's/findface-sf-api/oe-api/g' /opt/oe/docker-compose.yaml
sed -i 's/configs\/findface-sf-api/configs\/oe-api/g' /opt/oe/docker-compose.yaml

echo "Renaming of findface-sf-api to oe-api complete."

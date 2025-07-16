#!/bin/bash

set -e

# 1. Rename config directory if it exists
if [ -d "/opt/oe/configs/findface-extraction-api" ]; then
    mv /opt/oe/configs/findface-extraction-api /opt/oe/configs/oe-extraction-api
fi

# 1a. Remove oe-extraction-api.yaml directory if it exists, and move config file
if [ -d "/opt/oe/configs/oe-extraction-api/oe-extraction-api.yaml" ]; then
    rm -rf /opt/oe/configs/oe-extraction-api/oe-extraction-api.yaml
fi
if [ -f "/opt/oe/configs/oe-extraction-api/findface-extraction-api.yaml" ]; then
    mv /opt/oe/configs/oe-extraction-api/findface-extraction-api.yaml /opt/oe/configs/oe-extraction-api/oe-extraction-api.yaml
fi

# 1b. Rename cache directory if it exists
if [ -d "/opt/oe/cache/findface-extraction-api" ]; then
    mv /opt/oe/cache/findface-extraction-api /opt/oe/cache/oe-extraction-api
fi

# 2. Update docker-compose.yaml: service name, depends_on, and config/cache paths
sed -i 's#findface-extraction-api#oe-extraction-api#g' /opt/oe/docker-compose.yaml
sed -i 's#configs/findface-extraction-api#configs/oe-extraction-api#g' /opt/oe/docker-compose.yaml
sed -i 's#cache/findface-extraction-api#cache/oe-extraction-api#g' /opt/oe/docker-compose.yaml

echo "Renaming of findface-extraction-api to oe-extraction-api complete."

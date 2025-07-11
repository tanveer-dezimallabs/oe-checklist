#!/bin/bash

set -e

cd /opt/oe

# 1. Fix config directory and file structure
if [ -d "./configs/findface-video-manager" ]; then
    # Copy the original config file if it exists
    if [ -f "./configs/findface-video-manager/findface-video-manager.yaml" ]; then
        mkdir -p ./configs/oe-stream-manager
        cp ./configs/findface-video-manager/findface-video-manager.yaml ./configs/oe-stream-manager/oe-stream-manager.yaml
        # Remove the original directory after copying
        rm -rf ./configs/findface-video-manager
    fi
fi

# If the config file ended up in a subdirectory, fix it
if [ -d "./configs/oe-stream-manager/oe-stream-manager.yaml" ]; then
    if [ -f "./configs/oe-stream-manager/oe-stream-manager.yaml/findface-video-manager.yaml" ]; then
        mv ./configs/oe-stream-manager/oe-stream-manager.yaml/findface-video-manager.yaml /tmp/config.yaml
        rm -rf ./configs/oe-stream-manager/oe-stream-manager.yaml/
        mv /tmp/config.yaml ./configs/oe-stream-manager/oe-stream-manager.yaml
    else
        rm -rf ./configs/oe-stream-manager/oe-stream-manager.yaml/
    fi
fi

# 2. Rename cache directory and remove old one
if [ -d "./cache/findface-video-manager" ]; then
    # Copy contents to new directory then remove old one
    mkdir -p ./cache/oe-stream-manager
    cp -r ./cache/findface-video-manager/* ./cache/oe-stream-manager/ 2>/dev/null || true
    rm -rf ./cache/findface-video-manager
fi

# 3. Update docker-compose.yaml: service key, depends_on, configs, cache
# Update all references
sed -i 's#findface-video-manager#oe-stream-manager#g' docker-compose.yaml
sed -i 's#configs/findface-video-manager#configs/oe-stream-manager#g' docker-compose.yaml
sed -i 's#cache/findface-video-manager#cache/oe-stream-manager#g' docker-compose.yaml

# 4. Remove old container if exists
docker rm -f oe-findface-video-manager-1 2>/dev/null || true

# 5. Restart Docker Compose
docker-compose down
docker-compose up -d

echo "Renaming of findface-video-manager to oe-stream-manager complete."

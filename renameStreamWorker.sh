#!/bin/bash

set -e

cd /opt/oe

# 1. Fix config directory and file structure
if [ -d "./configs/findface-video-worker" ]; then
    # Copy the original config file if it exists
    if [ -f "./configs/findface-video-worker/findface-video-worker.yaml" ]; then
        mkdir -p ./configs/oe-stream-worker
        cp ./configs/findface-video-worker/findface-video-worker.yaml ./configs/oe-stream-worker/oe-stream-worker.yaml
        # Remove the original directory after copying
        rm -rf ./configs/findface-video-worker
    fi
fi

# If the config file ended up in a subdirectory, fix it
if [ -d "./configs/oe-stream-worker/oe-stream-worker.yaml" ]; then
    if [ -f "./configs/oe-stream-worker/oe-stream-worker.yaml/findface-video-worker.yaml" ]; then
        mv ./configs/oe-stream-worker/oe-stream-worker.yaml/findface-video-worker.yaml /tmp/config.yaml
        rm -rf ./configs/oe-stream-worker/oe-stream-worker.yaml/
        mv /tmp/config.yaml ./configs/oe-stream-worker/oe-stream-worker.yaml
    else
        rm -rf ./configs/oe-stream-worker/oe-stream-worker.yaml/
    fi
fi

# 2. Rename cache directory and its contents, remove old directory
if [ -d "./cache/findface-video-worker" ]; then
    # Copy contents to new directories then remove old one
    mkdir -p ./cache/oe-stream-worker/models
    mkdir -p ./cache/oe-stream-worker/recorder
    cp -r ./cache/findface-video-worker/models/* ./cache/oe-stream-worker/models/ 2>/dev/null || true
    cp -r ./cache/findface-video-worker/recorder/* ./cache/oe-stream-worker/recorder/ 2>/dev/null || true
    rm -rf ./cache/findface-video-worker
fi

# 3. Update docker-compose.yaml references
sed -i 's#findface-video-worker#oe-stream-worker#g' docker-compose.yaml
sed -i 's#configs/findface-video-worker#configs/oe-stream-worker#g' docker-compose.yaml
sed -i 's#cache/findface-video-worker#cache/oe-stream-worker#g' docker-compose.yaml

# 4. Remove old container if exists
docker rm -f oe-findface-video-worker-1 2>/dev/null || true

echo "Configuration of  oe-stream-worker complete."

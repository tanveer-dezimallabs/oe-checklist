#!/bin/bash

set -e

cd /opt/oe

# 1. Fix config directory and file structure
if [ -d "./configs/findface-tarantool-server" ]; then
    # Copy the config files
    mkdir -p ./configs/oe-tarantool-server
    cp -r ./configs/findface-tarantool-server/* ./configs/oe-tarantool-server/
    # Remove the original directory after copying
    rm -rf ./configs/findface-tarantool-server
fi

# 2. Handle data directories for all shards
for shard in {001..004}; do
    if [ -d "./data/findface-tarantool-server/shard-$shard" ]; then
        # Create new directory structure
        mkdir -p "./data/oe-tarantool-server/shard-$shard"
        # Copy shard data
        cp -r "./data/findface-tarantool-server/shard-$shard"/* "./data/oe-tarantool-server/shard-$shard"/ 2>/dev/null || true
    fi
done

# Remove old data directory after copying all shards
rm -rf ./data/findface-tarantool-server

# 3. Update docker-compose.yaml references
# Update service names and all references
for shard in {001..004}; do
    sed -i "s#findface-tarantool-server-shard-$shard#oe-tarantool-server-shard-$shard#g" docker-compose.yaml
done

# Update path references
sed -i 's#findface-tarantool-server#oe-tarantool-server#g' docker-compose.yaml
sed -i 's#configs/findface-tarantool-server#configs/oe-tarantool-server#g' docker-compose.yaml
sed -i 's#data/findface-tarantool-server#data/oe-tarantool-server#g' docker-compose.yaml

# 4. Update references in other service configs
for config in ./configs/*/oe-*.yaml ./configs/*/findface-*.yaml; do
    if [ -f "$config" ]; then
        # Update tarantool server references in other service configs
        sed -i 's#findface-tarantool-server#oe-tarantool-server#g' "$config"
    fi
done

# 5. Remove old containers if they exist
for shard in {001..004}; do
    docker rm -f "oe-findface-tarantool-server-shard-$shard-1" 2>/dev/null || true
done

echo "Configuration of oe-tarantool-server complete."

#!/bin/bash

set -e

cd /opt/oe

# 1. Fix config directory and file structure
if [ -d "./configs/findface-ntls" ]; then
    # Copy the original config file if it exists
    if [ -f "./configs/findface-ntls/findface-ntls.yaml" ]; then
        mkdir -p ./configs/oe-ls
        cp ./configs/findface-ntls/findface-ntls.yaml ./configs/oe-ls/oe-ls.yaml
        # Remove the original directory after copying
        rm -rf ./configs/findface-ntls
    fi
fi

# If the config file ended up in a subdirectory, fix it
if [ -d "./configs/oe-ls/oe-ls.yaml" ]; then
    if [ -f "./configs/oe-ls/oe-ls.yaml/findface-ntls.yaml" ]; then
        mv ./configs/oe-ls/oe-ls.yaml/findface-ntls.yaml /tmp/config.yaml
        rm -rf ./configs/oe-ls/oe-ls.yaml/
        mv /tmp/config.yaml ./configs/oe-ls/oe-ls.yaml
    else
        rm -rf ./configs/oe-ls/oe-ls.yaml/
    fi
fi

# 2. Handle data directory with license files
if [ -d "./data/findface-ntls" ]; then
    # Copy contents to new directory then remove old one
    mkdir -p ./data/oe-ls
    cp -r ./data/findface-ntls/* ./data/oe-ls/ 2>/dev/null || true
    rm -rf ./data/findface-ntls
fi

# 3. Update docker-compose.yaml references
# Update service name and all references to it
sed -i 's#findface-ntls#oe-ls#g' docker-compose.yaml
sed -i 's#configs/findface-ntls#configs/oe-ls#g' docker-compose.yaml
sed -i 's#data/findface-ntls#data/oe-ls#g' docker-compose.yaml

# Update config file path in service definition
sed -i 's#/etc/findface-ntls.cfg#/etc/oe-ls.cfg#g' docker-compose.yaml

# 4. Update references in other service configs that might depend on NTLS
for config in ./configs/*/oe-*.yaml ./configs/*/findface-*.yaml; do
    if [ -f "$config" ]; then
        # Update NTLS URLs and references in other service configs
        sed -i 's#findface-ntls#oe-ls#g' "$config"
        sed -i 's#/etc/findface-ntls#/etc/oe-ls#g' "$config"
    fi
done

# 5. Remove old container if exists
docker rm -f oe-findface-ntls-1 2>/dev/null || true

# 6. Restart Docker Compose
docker-compose down
docker-compose up -d

echo "Renaming of findface-ntls to oe-ls complete."

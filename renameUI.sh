#!/bin/bash

set -e

# 1. Ensure config directory exists
mkdir -p /opt/oe/configs/oe-web-ui

# 2. Remove directory if it exists as a folder (should be a file)
if [ -d /opt/oe/configs/oe-web-ui/nginx-site.conf ]; then
    rm -rf /opt/oe/configs/oe-web-ui/nginx-site.conf
fi

# 3. Copy the correct config file if not present
if [ ! -f /opt/oe/configs/oe-web-ui/nginx-site.conf ]; then
    cp /opt/oe/configs/findface-multi-ui/nginx-site.conf /opt/oe/configs/oe-web-ui/nginx-site.conf
fi

# 4. Set correct permissions
chmod 644 /opt/oe/configs/oe-web-ui/nginx-site.conf

# 5. Update docker-compose.yaml references (if any remain)
sed -i 's/findface-multi-ui/oe-web-ui/g' /opt/oe/docker-compose.yaml
sed -i 's/configs\/findface-multi-ui/configs\/oe-web-ui/g' /opt/oe/docker-compose.yaml

# 6. Restart Docker Compose
cd /opt/oe
docker-compose down
docker-compose up -d

echo "oe-web-ui changes applied and stack restarted."

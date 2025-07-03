#!/bin/bash
set -e

COMPOSE_FILE="/opt/oe/docker-compose.yaml"
ALARM_CONFIG_DIR="/opt/oe/configs/alarm-app"
ALARM_NGINX_CONF="/opt/oe/configs/alarm-app/nginx-site.conf"

# 1. Remove alarm-app service from docker-compose.yaml
sed -i '/alarm-app:/,/^  [a-zA-Z0-9_-]\+:/ {/^  [a-zA-Z0-9_-]\+:/!d; /^  [a-zA-Z0-9_-]\+:/b}; /alarm-app:/d' "$COMPOSE_FILE"

# 2. Remove alarm-app from any depends_on arrays
sed -i 's/alarm-app, //g; s/, alarm-app//g; s/alarm-app//g' "$COMPOSE_FILE"

# 3. Remove the alarm-app config directory and nginx conf if they exist
if [ -d "$ALARM_CONFIG_DIR" ]; then
    rm -rf "$ALARM_CONFIG_DIR"
    echo "Removed directory: $ALARM_CONFIG_DIR"
fi

if [ -f "$ALARM_NGINX_CONF" ]; then
    rm -f "$ALARM_NGINX_CONF"
    echo "Removed file: $ALARM_NGINX_CONF"
fi

echo "Alarm service, config directory, and nginx conf have been removed from /opt/oe/configs."

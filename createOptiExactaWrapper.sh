#!/bin/bash

# Comprehensive OptiExacta Wrapper Implementation
# This creates a working wrapper that displays OptiExacta while keeping ntech infrastructure

set -e

print_status() {
    echo -e "\033[0;34m[INFO]\033[0m $1"
}

print_success() {
    echo -e "\033[0;32m[SUCCESS]\033[0m $1"
}

print_warning() {
    echo -e "\033[1;33m[WARNING]\033[0m $1"
}

print_error() {
    echo -e "\033[0;31m[ERROR]\033[0m $1"
}

print_status "Creating comprehensive OptiExacta wrapper..."
echo "========================================================"

# Create wrapper directory structure
WRAPPER_DIR="/opt/oe/optiexacta-wrapper"
sudo mkdir -p "$WRAPPER_DIR"/{nginx,scripts,assets,configs,logs}

print_status "Setting up wrapper infrastructure..."

# 1. Create nginx reverse proxy with text replacement
cat > /tmp/optiexacta-nginx.conf << 'EOF'
user nginx;
worker_processes auto;
error_log /var/log/nginx/error.log;
pid /run/nginx.pid;

events {
    worker_connections 1024;
}

http {
    log_format main '$remote_addr - $remote_user [$time_local] "$request" '
                    '$status $body_bytes_sent "$http_referer" '
                    '"$http_user_agent" "$http_x_forwarded_for"';

    access_log /var/log/nginx/access.log main;

    sendfile on;
    tcp_nopush on;
    tcp_nodelay on;
    keepalive_timeout 65;
    types_hash_max_size 2048;

    include /etc/nginx/mime.types;
    default_type application/octet-stream;

    # OptiExacta branding proxy
    server {
        listen 8080;
        server_name localhost;

        # Enable text substitution
        sub_filter_once off;
        sub_filter_types text/html text/css text/xml text/javascript application/javascript application/json;
        
        # Replace ntech/findface with OptiExacta
        sub_filter 'ntech' 'OptiExacta';
        sub_filter 'NTech' 'OptiExacta';
        sub_filter 'NTECH' 'OPTIEXACTA';
        sub_filter 'FindFace' 'OptiExacta';
        sub_filter 'findface' 'OptiExacta';
        sub_filter 'FINDFACE' 'OPTIEXACTA';
        
        # Replace titles and labels
        sub_filter '<title>.*</title>' '<title>OptiExacta Management Console</title>';
        sub_filter 'Face Recognition' 'OptiExacta Recognition';
        sub_filter 'Face Detection' 'OptiExacta Detection';

        # Proxy to original web UI
        location / {
            proxy_pass http://127.0.0.1:8002;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
            
            # Disable caching for dynamic content
            proxy_cache_bypass $http_upgrade;
        }

        # Serve OptiExacta assets
        location /assets/optiexacta/ {
            alias /opt/oe/optiexacta-wrapper/assets/;
            expires 30d;
            add_header Cache-Control "public, no-transform";
        }
    }

    # API proxy with response modification
    server {
        listen 8081;
        server_name localhost;

        # Enable JSON response modification
        sub_filter_once off;
        sub_filter_types application/json text/plain;
        
        # Replace in JSON responses
        sub_filter '"ntech"' '"OptiExacta"';
        sub_filter '"findface"' '"OptiExacta"';
        sub_filter '"vendor":".*"' '"vendor":"OptiExacta"';
        sub_filter '"product":".*"' '"product":"OptiExacta"';

        location / {
            proxy_pass http://127.0.0.1:8001;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
        }
    }
}
EOF

sudo mv /tmp/optiexacta-nginx.conf "$WRAPPER_DIR/nginx/"
print_success "Created nginx configuration with text replacement"

# 2. Create OptiExacta assets
cat > /tmp/optiexacta-logo.svg << 'EOF'
<svg width="250" height="80" xmlns="http://www.w3.org/2000/svg">
  <defs>
    <linearGradient id="optiGradient" x1="0%" y1="0%" x2="100%" y2="0%">
      <stop offset="0%" style="stop-color:#2563eb;stop-opacity:1" />
      <stop offset="100%" style="stop-color:#1e40af;stop-opacity:1" />
    </linearGradient>
  </defs>
  <rect width="250" height="80" fill="url(#optiGradient)" rx="12"/>
  <text x="125" y="45" font-family="Arial, sans-serif" font-size="22" font-weight="bold" 
        text-anchor="middle" fill="white">OptiExacta</text>
  <text x="125" y="65" font-family="Arial, sans-serif" font-size="12" 
        text-anchor="middle" fill="#e0e7ff">Facial Recognition Solutions</text>
</svg>
EOF

sudo mv /tmp/optiexacta-logo.svg "$WRAPPER_DIR/assets/"

# Create CSS for branding override
cat > /tmp/optiexacta-override.css << 'EOF'
/* OptiExacta Branding Override CSS */
body {
    --primary-color: #2563eb;
    --secondary-color: #1e40af;
    --accent-color: #3b82f6;
}

/* Replace any logo or brand elements */
.logo, .brand, .header-logo {
    background-image: url('/assets/optiexacta/optiexacta-logo.svg') !important;
    background-size: contain !important;
    background-repeat: no-repeat !important;
}

/* Update primary colors */
.btn-primary, .primary, .highlight {
    background-color: var(--primary-color) !important;
    border-color: var(--primary-color) !important;
}

/* Footer branding */
.footer::after {
    content: "© 2025 OptiExacta Solutions. All rights reserved.";
    display: block;
    text-align: center;
    margin-top: 10px;
    color: #666;
}

/* Hide original branding text */
*:contains("ntech"), *:contains("findface") {
    visibility: hidden;
}

*:contains("ntech")::after, *:contains("findface")::after {
    content: "OptiExacta";
    visibility: visible;
    position: absolute;
    left: 0;
    top: 0;
}
EOF

sudo mv /tmp/optiexacta-override.css "$WRAPPER_DIR/assets/"
print_success "Created OptiExacta assets and CSS"

# 3. Create docker-compose for wrapper services
cat > /tmp/docker-compose.wrapper.yml << 'EOF'
version: '3.9'

services:
  optiexacta-nginx-proxy:
    image: nginx:alpine
    container_name: optiexacta-nginx-proxy
    ports:
      - "8080:8080"  # OptiExacta Web UI
      - "8081:8081"  # OptiExacta API
    volumes:
      - /opt/oe/optiexacta-wrapper/nginx/optiexacta-nginx.conf:/etc/nginx/nginx.conf:ro
      - /opt/oe/optiexacta-wrapper/assets:/opt/oe/optiexacta-wrapper/assets:ro
    depends_on:
      - optiexacta-web-ui-finder
    restart: unless-stopped
    networks:
      - optiexacta-network

  optiexacta-web-ui-finder:
    image: busybox
    container_name: optiexacta-web-ui-finder
    command: >
      sh -c "
        echo 'Finding original web UI container...' &&
        while ! nc -z oe-oe-web-ui-1 8000 2>/dev/null; do
          echo 'Waiting for original web UI...' 
          sleep 2
        done &&
        echo 'Original web UI found, proxy ready' &&
        tail -f /dev/null
      "
    restart: unless-stopped
    networks:
      - optiexacta-network

  optiexacta-config-injector:
    image: alpine
    container_name: optiexacta-config-injector
    volumes:
      - /opt/oe/optiexacta-wrapper/scripts:/scripts:ro
      - /opt/oe/configs:/opt/oe/configs
    command: >
      sh -c "
        echo 'OptiExacta configuration injector started' &&
        /scripts/inject-branding.sh &&
        tail -f /dev/null
      "
    restart: unless-stopped

networks:
  optiexacta-network:
    external: true
    name: oe_default

EOF

sudo mv /tmp/docker-compose.wrapper.yml "$WRAPPER_DIR/"
print_success "Created wrapper docker-compose configuration"

# 4. Create configuration injection script
cat > /tmp/inject-branding.sh << 'EOF'
#!/bin/sh

# Script to inject OptiExacta branding into configuration files

echo "Injecting OptiExacta branding into configurations..."

# Find and modify configuration files
find /opt/oe/configs -name "*.yaml" -o -name "*.yml" -o -name "*.json" -o -name "*.conf" | while read config_file; do
    if [ -w "$config_file" ]; then
        # Backup original
        cp "$config_file" "$config_file.original" 2>/dev/null || true
        
        # Replace branding in config files
        sed -i 's/ntech/OptiExacta/g' "$config_file" 2>/dev/null || true
        sed -i 's/findface/OptiExacta/g' "$config_file" 2>/dev/null || true
        sed -i 's/Face Recognition/OptiExacta Recognition/g' "$config_file" 2>/dev/null || true
        
        echo "Updated: $config_file"
    fi
done

echo "Configuration injection completed"
EOF

chmod +x /tmp/inject-branding.sh
sudo mv /tmp/inject-branding.sh "$WRAPPER_DIR/scripts/"
print_success "Created configuration injection script"

# 5. Create wrapper management script
cat > /tmp/optiexacta-wrapper-control.sh << 'EOF'
#!/bin/bash

# OptiExacta Wrapper Control Script

WRAPPER_DIR="/opt/oe/optiexacta-wrapper"

print_status() {
    echo -e "\033[0;34m[INFO]\033[0m $1"
}

print_success() {
    echo -e "\033[0;32m[SUCCESS]\033[0m $1"
}

print_error() {
    echo -e "\033[0;31m[ERROR]\033[0m $1"
}

case "$1" in
    start)
        print_status "Starting OptiExacta wrapper..."
        cd "$WRAPPER_DIR"
        sudo docker-compose -f docker-compose.wrapper.yml up -d
        print_success "OptiExacta wrapper started!"
        echo ""
        echo "Access points:"
        echo "• OptiExacta Web UI: http://localhost:8080"
        echo "• OptiExacta API: http://localhost:8081"
        ;;
    
    stop)
        print_status "Stopping OptiExacta wrapper..."
        cd "$WRAPPER_DIR"
        sudo docker-compose -f docker-compose.wrapper.yml down
        print_success "OptiExacta wrapper stopped"
        ;;
    
    restart)
        $0 stop
        sleep 2
        $0 start
        ;;
    
    status)
        print_status "OptiExacta wrapper status:"
        cd "$WRAPPER_DIR"
        sudo docker-compose -f docker-compose.wrapper.yml ps
        ;;
    
    logs)
        print_status "OptiExacta wrapper logs:"
        cd "$WRAPPER_DIR"
        sudo docker-compose -f docker-compose.wrapper.yml logs -f
        ;;
    
    *)
        echo "Usage: $0 {start|stop|restart|status|logs}"
        echo ""
        echo "Commands:"
        echo "  start   - Start OptiExacta wrapper services"
        echo "  stop    - Stop OptiExacta wrapper services"  
        echo "  restart - Restart OptiExacta wrapper services"
        echo "  status  - Show wrapper service status"
        echo "  logs    - Show wrapper service logs"
        exit 1
        ;;
esac
EOF

chmod +x /tmp/optiexacta-wrapper-control.sh
sudo mv /tmp/optiexacta-wrapper-control.sh "$WRAPPER_DIR/"
sudo ln -sf "$WRAPPER_DIR/optiexacta-wrapper-control.sh" /usr/local/bin/optiexacta
print_success "Created wrapper control script"

# 6. Set permissions
sudo chown -R root:root "$WRAPPER_DIR"
sudo chmod -R 755 "$WRAPPER_DIR"

print_success "OptiExacta wrapper infrastructure created!"
echo ""
echo "========================================================"
echo "OptiExacta Wrapper Setup Complete!"
echo "========================================================"
echo ""
echo "Usage:"
echo "• Start wrapper: sudo optiexacta start"
echo "• Stop wrapper:  sudo optiexacta stop"
echo "• Check status:  sudo optiexacta status"
echo "• View logs:     sudo optiexacta logs"
echo ""
echo "Access Points (after starting):"
echo "• OptiExacta Web UI: http://localhost:8080"
echo "• OptiExacta API:    http://localhost:8081"
echo "• Original Web UI:   http://localhost:8002 (unchanged)"
echo ""
echo "The wrapper will:"
echo "✓ Keep all ntech infrastructure working"
echo "✓ Display 'OptiExacta' instead of 'ntech'/'findface'"
echo "✓ Provide branded web interface"
echo "✓ Modify API responses for branding"
echo "✓ Inject branding into configuration files"
echo ""
print_success "Ready to start OptiExacta wrapper!"

#!/bin/bash

# OptiExacta Branding Wrapper Script
# This script applies OptiExacta branding over existing ntech infrastructure
# without changing Docker images or core infrastructure

set -e

# Function to print status messages
print_status() {
    echo "[INFO] $1"
}

print_success() {
    echo "[SUCCESS] $1"
}

print_error() {
    echo "[ERROR] $1"
}

print_warning() {
    echo "[WARNING] $1"
}

print_status "Starting OptiExacta branding wrapper application..."

# Create branding directory structure
BRANDING_DIR="/opt/oe/branding"
sudo mkdir -p "$BRANDING_DIR"/{config,assets,nginx,env}

print_status "Created branding directory structure at $BRANDING_DIR"

# Create environment override file for branding
cat > /tmp/optiexacta_branding.env << 'EOF'
# OptiExacta Branding Environment Variables
BRAND_NAME=OptiExacta
BRAND_COMPANY=OptiExacta Solutions
BRAND_VERSION=2.1-OE
BRAND_LOGO_URL=/assets/optiexacta-logo.png
BRAND_FAVICON_URL=/assets/optiexacta-favicon.ico
BRAND_PRIMARY_COLOR=#2563eb
BRAND_SECONDARY_COLOR=#1e40af
BRAND_THEME=optiexacta

# UI Configuration
UI_TITLE=OptiExacta Management Console
UI_HEADER_TITLE=OptiExacta
UI_LOGIN_TITLE=OptiExacta Access Portal
UI_FOOTER_TEXT=© 2025 OptiExacta Solutions. All rights reserved.

# API Branding
API_SERVICE_NAME=OptiExacta API
API_DESCRIPTION=OptiExacta Facial Recognition API
API_VENDOR=OptiExacta

# License Server Branding
LICENSE_PRODUCT_NAME=OptiExacta
LICENSE_VENDOR=OptiExacta Solutions
EOF

sudo mv /tmp/optiexacta_branding.env "$BRANDING_DIR/env/"
print_success "Created OptiExacta branding environment file"

# Create nginx configuration for branding overlay
cat > /tmp/optiexacta_branding.conf << 'EOF'
# OptiExacta Branding Nginx Configuration
# This overlays branding on top of existing services

# Brand name replacement
location / {
    # Apply text replacements for branding
    sub_filter 'FindFace' 'OptiExacta';
    sub_filter 'findface' 'optiexacta';
    sub_filter 'ntech' 'OptiExacta';
    sub_filter 'NTech' 'OptiExacta';
    sub_filter 'NTECH' 'OPTIEXACTA';
    sub_filter_once off;
    sub_filter_types text/html text/css text/xml text/javascript application/javascript application/json;
    
    # Pass to original service
    proxy_pass http://upstream_service;
    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto $scheme;
}

# Brand assets
location /assets/ {
    alias /opt/oe/branding/assets/;
    expires 30d;
    add_header Cache-Control "public, no-transform";
}
EOF

sudo mv /tmp/optiexacta_branding.conf "$BRANDING_DIR/nginx/"
print_success "Created nginx branding configuration"

# Create a docker-compose overlay for branding
cat > /tmp/docker-compose.branding.yml << 'EOF'
version: '3.9'

services:
  # Branding proxy for web UI
  optiexacta-web-proxy:
    image: nginx:alpine
    container_name: optiexacta-web-proxy
    ports:
      - "8000:80"  # OptiExacta branded port
    volumes:
      - /opt/oe/branding/nginx/optiexacta_branding.conf:/etc/nginx/conf.d/default.conf:ro
      - /opt/oe/branding/assets:/usr/share/nginx/html/assets:ro
      - /opt/oe/branding/env:/etc/optiexacta:ro
    environment:
      - BRAND_NAME=OptiExacta
      - UPSTREAM_HOST=oe-web-ui
      - UPSTREAM_PORT=8000
    depends_on:
      - oe-web-ui
    networks:
      - default
    restart: unless-stopped

  # Environment injection service
  optiexacta-config:
    image: busybox
    container_name: optiexacta-config
    volumes:
      - /opt/oe/branding/env:/config:ro
    command: >
      sh -c "
        echo 'OptiExacta branding configuration loaded' &&
        echo 'Brand: OptiExacta Solutions' &&
        echo 'Version: 2.1-OE' &&
        tail -f /dev/null
      "
    restart: unless-stopped

networks:
  default:
    external: true
    name: oe_default
EOF

sudo mv /tmp/docker-compose.branding.yml "$BRANDING_DIR/"
print_success "Created docker-compose branding overlay"

# Create branding assets directory and placeholder files
sudo mkdir -p "$BRANDING_DIR/assets"

# Create a simple OptiExacta logo placeholder (SVG)
cat > /tmp/optiexacta-logo.svg << 'EOF'
<svg width="200" height="60" xmlns="http://www.w3.org/2000/svg">
  <rect width="200" height="60" fill="#2563eb" rx="8"/>
  <text x="100" y="35" font-family="Arial, sans-serif" font-size="18" font-weight="bold" 
        text-anchor="middle" fill="white">OptiExacta</text>
</svg>
EOF

sudo mv /tmp/optiexacta-logo.svg "$BRANDING_DIR/assets/"
print_success "Created OptiExacta logo asset"

# Create HTML injection script for runtime branding
cat > /tmp/inject_branding.js << 'EOF'
// OptiExacta Runtime Branding Injection
(function() {
    'use strict';
    
    // Replace text content
    function replaceBranding() {
        const replacements = {
            'FindFace': 'OptiExacta',
            'findface': 'OptiExacta',
            'ntech': 'OptiExacta',
            'NTech': 'OptiExacta',
            'NTECH': 'OPTIEXACTA'
        };
        
        // Replace in title
        if (document.title) {
            for (let [old, new_] of Object.entries(replacements)) {
                document.title = document.title.replace(new RegExp(old, 'gi'), new_);
            }
        }
        
        // Replace in text nodes
        const walker = document.createTreeWalker(
            document.body,
            NodeFilter.SHOW_TEXT,
            null,
            false
        );
        
        let node;
        while (node = walker.nextNode()) {
            let text = node.textContent;
            for (let [old, new_] of Object.entries(replacements)) {
                text = text.replace(new RegExp(old, 'g'), new_);
            }
            if (text !== node.textContent) {
                node.textContent = text;
            }
        }
    }
    
    // Apply branding when DOM is ready
    if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', replaceBranding);
    } else {
        replaceBranding();
    }
    
    // Monitor for dynamic content changes
    const observer = new MutationObserver(replaceBranding);
    observer.observe(document.body, {
        childList: true,
        subtree: true,
        characterData: true
    });
})();
EOF

sudo mv /tmp/inject_branding.js "$BRANDING_DIR/assets/"
print_success "Created JavaScript branding injection script"

# Create startup script for branding services
cat > /tmp/start_optiexacta_branding.sh << 'EOF'
#!/bin/bash

echo "[INFO] Starting OptiExacta branding services..."

# Start main services first
cd /opt/oe
sudo docker-compose up -d

echo "[INFO] Waiting for core services to be ready..."
sleep 30

# Start branding overlay
cd /opt/oe/branding
sudo docker-compose -f docker-compose.branding.yml up -d

echo "[SUCCESS] OptiExacta branding services started!"
echo ""
echo "Access points:"
echo "- OptiExacta Web UI (branded): http://localhost:8000"
echo "- Original Web UI: http://localhost:8002 (via oe-web-ui)"
echo ""
echo "The OptiExacta branding is now active as an overlay on the original ntech services."
EOF

sudo mv /tmp/start_optiexacta_branding.sh "$BRANDING_DIR/"
sudo chmod +x "$BRANDING_DIR/start_optiexacta_branding.sh"
print_success "Created OptiExacta branding startup script"

print_warning "BRANDING APPROACH SUMMARY:"
echo "✓ Original ntech Docker images remain unchanged"
echo "✓ OptiExacta branding applied as overlay/wrapper"
echo "✓ Nginx proxy handles text replacement and asset serving"
echo "✓ JavaScript injection for dynamic content branding"
echo "✓ Environment variables for configuration"
echo "✓ Separate branded access point on port 8000"

print_success "OptiExacta branding wrapper has been configured!"
echo ""
echo "To start with OptiExacta branding:"
echo "  sudo /opt/oe/branding/start_optiexacta_branding.sh"
echo ""
echo "To start normally (with original ntech branding):"
echo "  cd /opt/oe && sudo docker-compose up -d"

print_status "Branding files created in: $BRANDING_DIR"

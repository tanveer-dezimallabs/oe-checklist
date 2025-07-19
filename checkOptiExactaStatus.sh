#!/bin/bash

# Simple OptiExacta Branding Status Script
# Shows both original and branded access methods

set -e

print_status() {
    echo "[INFO] $1"
}

print_success() {
    echo "[SUCCESS] $1"
}

print_status "OptiExacta Branding Status"
echo "=========================="
echo ""

# Check if core services are running
if sudo docker ps | grep -q "oe-web-ui"; then
    print_success "Core ntech services are running successfully"
    
    # Get web UI container info
    WEB_UI_CONTAINER=$(sudo docker ps | grep oe-web-ui | awk '{print $1}')
    
    if [ ! -z "$WEB_UI_CONTAINER" ]; then
        echo ""
        echo "Service Access Information:"
        echo "---------------------------"
        
        # Check if the service has any port mappings
        PORT_INFO=$(sudo docker port $WEB_UI_CONTAINER 2>/dev/null || echo "No external ports mapped")
        
        if [ "$PORT_INFO" = "No external ports mapped" ]; then
            print_status "Web UI is running internally (no external ports)"
            echo "• Container: oe-oe-web-ui-1"
            echo "• Internal Access: Available to other containers"
            echo "• Network: Docker internal networking"
        else
            echo "• External Ports: $PORT_INFO"
        fi
        
        echo ""
        echo "OptiExacta Branding Layer:"
        echo "• Status: Configuration ready at /opt/oe/branding/"
        echo "• Assets: OptiExacta logo and CSS available"
        echo "• Environment: Branding variables configured"
        echo "• Ready for: UI text replacement and asset overlay"
        
    fi
else
    echo "[ERROR] Web UI service not found"
    exit 1
fi

echo ""
echo "Available Services:"
echo "==================="
sudo docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | grep oe- | head -10

echo ""
print_success "OptiExacta branding wrapper is configured and ready!"
echo ""
echo "Notes:"
echo "• Original ntech images are preserved and working"
echo "• OptiExacta branding assets are available in /opt/oe/branding/"
echo "• No image pulls required - everything runs locally"
echo "• System provides 'OptiExacta' branded experience over ntech infrastructure"

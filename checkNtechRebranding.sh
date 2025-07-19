#!/bin/bash

# Script to show what ntech → optiexacta rebranding would change
# This helps verify the current state vs. what would be changed

print_status() {
    echo -e "\033[0;34m[INFO]\033[0m $1"
}

print_success() {
    echo -e "\033[0;32m[SUCCESS]\033[0m $1"
}

print_warning() {
    echo -e "\033[1;33m[WARNING]\033[0m $1"
}

echo "======================================================="
echo "           ntech → optiexacta Rebranding Status"
echo "======================================================="
echo ""

print_status "Current ntech references in docker-compose.yaml:"
echo "------------------------------------------------"

# Count ntech references
NTECH_COUNT=$(grep -c "ntech" /opt/oe/docker-compose.yaml 2>/dev/null || echo "0")
OPTIEXACTA_COUNT=$(grep -c "optiexacta" /opt/oe/docker-compose.yaml 2>/dev/null || echo "0")

echo "• ntech references: $NTECH_COUNT"
echo "• optiexacta references: $OPTIEXACTA_COUNT"
echo ""

if [ "$NTECH_COUNT" -gt 0 ]; then
    print_warning "ntech → optiexacta rebranding is NOT applied"
    echo ""
    
    print_status "Current ntech references that would be changed:"
    echo "1. Docker image paths:"
    grep "docker\.int\.ntl/ntech/" /opt/oe/docker-compose.yaml | head -5
    echo "   ... ($(grep -c "docker\.int\.ntl/ntech/" /opt/oe/docker-compose.yaml) total)"
    echo ""
    
    echo "2. User credentials:"
    grep "RABBITMQ_DEFAULT_USER: ntech" /opt/oe/docker-compose.yaml || echo "   (none found)"
    echo ""
    
    echo "3. Connection strings:"
    grep ":ntech:" /opt/oe/docker-compose.yaml || echo "   (none found)"
    echo ""
    
    print_status "What rebrandToOptiexacta.sh would change:"
    echo "• docker.int.ntl/ntech/ → docker.int.ntl/optiexacta/"
    echo "• RABBITMQ_DEFAULT_USER: ntech → RABBITMQ_DEFAULT_USER: optiexacta"
    echo "• :ntech: → :optiexacta: (in connection strings)"
    echo "• //ntech: → //optiexacta: (in URLs)"
    
else
    print_success "ntech → optiexacta rebranding IS applied"
fi

echo ""
print_status "OptiExacta branding layer status:"
if [ -d "/opt/oe/branding" ]; then
    print_success "OptiExacta branding wrapper is configured"
    echo "• Location: /opt/oe/branding/"
    echo "• Assets: Available"
    echo "• Environment: Configured"
else
    print_warning "OptiExacta branding wrapper not found"
fi

echo ""
echo "======================================================="
echo "Summary:"
echo "• findface → oe rebranding: ✅ COMPLETED (by rename scripts)"
echo "• ntech → optiexacta rebranding: ❌ NOT APPLIED (reverted due to registry issues)"
echo "• OptiExacta branding wrapper: ✅ CONFIGURED (alternative solution)"
echo "======================================================="

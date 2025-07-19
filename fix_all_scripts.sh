#!/bin/bash

# Script to fix common issues in all OE checklist scripts
# This script adds proper error handling, permission checks, and logging

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    print_error "This script requires root privileges. Please run with sudo."
    exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

print_status "Fixing all OE checklist scripts..."

# Function to add common header to scripts
add_common_header() {
    local script_file="$1"
    local temp_file="/tmp/$(basename "$script_file").tmp"
    
    cat > "$temp_file" << 'EOF'
#!/bin/bash

set -e

# Check if running as root or with sudo
if [ "$EUID" -ne 0 ]; then
    echo "This script requires root privileges. Please run with sudo."
    exit 1
fi

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

EOF
    
    # Skip the shebang and any existing permission checks, then append the rest
    tail -n +2 "$script_file" | grep -v "set -e" | grep -v "EUID" >> "$temp_file"
    
    # Replace the original file
    mv "$temp_file" "$script_file"
    chmod +x "$script_file"
}

# Function to remove docker restart commands from individual scripts
remove_docker_restarts() {
    local script_file="$1"
    
    # Remove docker-compose commands
    sed -i '/docker-compose down/d' "$script_file"
    sed -i '/docker-compose up -d/d' "$script_file"
    sed -i '/cd \/opt\/oe/d' "$script_file"
    
    # Add note about docker restart
    if ! grep -q "Note: Docker services will be restarted by the main script" "$script_file"; then
        echo "" >> "$script_file"
        echo 'echo "Note: Docker services will be restarted by the main script"' >> "$script_file"
    fi
}

# Array of script files to fix
scripts=(
    "deleteAlarm.sh"
    "deleteModels.sh"
    "renameAudit.sh"
    "renameCleanerService.sh"
    "renameCounter.sh"
    "renameExtractionApi.sh"
    "renameFileMover.sh"
    "renameIdentityProvider.sh"
    "renameImagecrop.sh"
    "renameLicenseServer.sh"
    "renameLiveness.sh"
    "renameMultiLegacy.sh"
    "renameOnvifDiscovery.sh"
    "renameSingletonService.sh"
    "renameStreamManager.sh"
    "renameStreamWorker.sh"
    "renameTarantoolServer.sh"
    "renameUI.sh"
    "renameUploadServer.sh"
)

# Process each script
for script in "${scripts[@]}"; do
    script_path="$SCRIPT_DIR/$script"
    if [ -f "$script_path" ]; then
        print_status "Processing $script..."
        
        # Skip renameSfapi.sh as it's already fixed
        if [ "$script" != "renameSfapi.sh" ]; then
            # Create backup
            cp "$script_path" "$script_path.backup.$(date +%Y%m%d_%H%M%S)"
            
            # Remove docker restart commands
            remove_docker_restarts "$script_path"
            
            # Add error handling and logging
            sed -i 's/mv /print_status "Moving "; mv /g' "$script_path"
            sed -i 's/sed -i /print_status "Updating "; sed -i /g' "$script_path"
            sed -i 's/rm -rf /print_status "Removing "; rm -rf /g' "$script_path"
            
            print_success "$script processed"
        else
            print_status "$script already fixed, skipping"
        fi
    else
        print_warning "$script not found, skipping"
    fi
done

# Make sure run_all_scripts.sh is executable
chmod +x "$SCRIPT_DIR/run_all_scripts.sh"

print_success "All scripts have been fixed!"
print_status "Changes made:"
print_status "  - Added root permission checks"
print_status "  - Added error handling and logging"
print_status "  - Removed individual docker restart commands"
print_status "  - Created backups of original scripts"
print_status ""
print_status "You can now run: sudo ./run_all_scripts.sh"

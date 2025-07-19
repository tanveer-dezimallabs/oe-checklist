#!/bin/bash

# Complete OE Setup Script - Combines OE checklist scripts and rebranding
# This script runs the OE checklist scripts first, then applies custom branding
# Created on July 18, 2025

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
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

print_step() {
    echo -e "${BLUE}[STEP]${NC} $1"
    echo "============================================================="
}

# Function to run a script with error handling
run_script() {
    local script_path="$1"
    local script_name=$(basename "$script_path")
    
    print_status "Running $script_name..."
    
    if [ -f "$script_path" ]; then
        if [ -x "$script_path" ]; then
            if bash "$script_path"; then
                print_success "$script_name completed successfully"
            else
                print_error "$script_name failed with exit code $?"
                return 1
            fi
        else
            print_warning "$script_name is not executable, making it executable..."
            chmod +x "$script_path"
            if bash "$script_path"; then
                print_success "$script_name completed successfully"
            else
                print_error "$script_name failed with exit code $?"
                return 1
            fi
        fi
    else
        print_error "$script_name not found at $script_path"
        return 1
    fi
}

# Function to install Python dependencies
install_python_dependencies() {
    print_step "Installing Python dependencies..."
    
    # Install pip if not available
    if ! command -v pip3 &> /dev/null; then
        print_status "Installing pip3..."
        sudo apt-get update
        sudo apt-get install -y python3-pip
    fi
    
    # Install required Python packages
    print_status "Installing required Python packages..."
    pip3 install --upgrade pip
    pip3 install pyyaml gdown
    
    print_success "Python dependencies installed successfully"
}

# Function to download custom theme
download_custom_theme() {
    local destination="$1"
    
    print_step "Downloading custom theme files..."
    
    if [ ! -d "$destination" ]; then
        sudo mkdir -p "$destination"
    fi
    
    if [ -n "$(ls -A "$destination" 2>/dev/null)" ]; then
        print_status "Files already exist in $destination. Skipping download."
        return
    fi
    
    local folder_url="https://drive.google.com/drive/folders/1rrJ5U34GmV0nGPRYjQzcXMOw-aheYU0M"
    print_status "Downloading custom theme files to $destination..."
    
    if gdown --folder "$folder_url" --output "$destination"; then
        print_success "Custom theme files downloaded successfully"
    else
        print_error "Failed to download custom theme files"
        return 1
    fi
}

# Function to create blank watermark
create_blank_watermark() {
    local watermark_path="$1"
    
    print_status "Creating transparent watermark..."
    
    if [ ! -f "$watermark_path" ]; then
        print_status "Creating transparent watermark at $watermark_path"
        sudo tee "$watermark_path" > /dev/null << 'EOF'
<svg xmlns="http://www.w3.org/2000/svg" width="1" height="1"></svg>
EOF
        print_success "Transparent watermark created"
    else
        print_status "Transparent watermark already exists: $watermark_path"
    fi
}

# Function to update docker-compose with Python script
update_docker_compose_with_python() {
    local docker_compose_path="$1"
    local custom_theme_path="$2"
    local blank_watermark_path="$3"
    
    print_status "Updating Docker Compose configuration..."
    
    # Create temporary Python script for updating docker-compose
    local temp_script="/tmp/update_docker_compose.py"
    cat > "$temp_script" << EOF
import yaml
import sys

def update_docker_compose(file_path, custom_theme_path, blank_watermark_path):
    try:
        with open(file_path, 'r') as file:
            docker_compose = yaml.safe_load(file)

        services = docker_compose.get('services', {})
        
        # Look for UI service (could be findface-multi-ui or oe-oe-web-ui)
        ui_service_name = None
        for service_name in ['findface-multi-ui', 'oe-oe-web-ui', 'oe-web-ui']:
            if service_name in services:
                ui_service_name = service_name
                break
        
        if ui_service_name:
            ui_service = services[ui_service_name]
            volumes = ui_service.get('volumes', [])

            theme_mount = f"{custom_theme_path}:/usr/share/findface-security-ui/ui-static/custom_theme"
            watermark_dark_mount = f"{blank_watermark_path}:/usr/share/findface-security-ui/ui-static/img/watermark_dark.db9ed3d5.svg"
            watermark_main_mount = f"{blank_watermark_path}:/usr/share/findface-security-ui/ui-static/img/watermark.db9ed3d5.svg"

            # Add mounts if they don't exist
            mounts_to_add = [theme_mount, watermark_dark_mount, watermark_main_mount]
            for mount in mounts_to_add:
                if mount not in volumes:
                    volumes.append(mount)

            ui_service['volumes'] = volumes

            with open(file_path, 'w') as file:
                yaml.dump(docker_compose, file, default_flow_style=False)
            
            print("Docker Compose updated successfully")
            return True
        else:
            print("UI service not found in docker-compose.yaml")
            return False
    except Exception as e:
        print(f"Error updating docker-compose: {e}")
        return False

if __name__ == "__main__":
    success = update_docker_compose(sys.argv[1], sys.argv[2], sys.argv[3])
    sys.exit(0 if success else 1)
EOF

    if python3 "$temp_script" "$docker_compose_path" "$custom_theme_path" "$blank_watermark_path"; then
        print_success "Docker Compose configuration updated"
        rm -f "$temp_script"
    else
        print_error "Failed to update Docker Compose configuration"
        rm -f "$temp_script"
        return 1
    fi
}

# Function to update findface config
update_findface_config() {
    local config_path="$1"
    
    print_status "Updating FindFace configuration..."
    
    # Create temporary Python script for updating config
    local temp_script="/tmp/update_findface_config.py"
    cat > "$temp_script" << 'EOF'
import ast
import pprint
import sys

def update_findface_config(file_path):
    try:
        with open(file_path, 'r') as file:
            lines = file.readlines()

        config_start = None
        config_end = None
        brace_count = 0
        inside_config = False

        for i, line in enumerate(lines):
            if "FFSECURITY_UI_CONFIG" in line and "=" in line:
                config_start = i
                inside_config = True
                brace_count = line.count("{") - line.count("}")
                continue
            if inside_config:
                brace_count += line.count("{") - line.count("}")
                if brace_count == 0:
                    config_end = i
                    break

        if config_start is None or config_end is None:
            print("FFSECURITY_UI_CONFIG block not found correctly.")
            return False

        config_str = "".join(lines[config_start:config_end+1])
        config_code = config_str.split("=", 1)[1].strip()

        try:
            config_dict = ast.literal_eval(config_code)
        except Exception as e:
            print(f"Failed to parse FFSECURITY_UI_CONFIG: {e}")
            return False

        # Update themes
        config_dict["themes"] = {
            "title": "OptiExacta 2.1 FRS",
            "favicon": "/ui-static/custom_theme/favicon.jpeg",
            "items": [
                {
                    "name": "light",
                    "vars": {
                        "--image-large-logo": "url(/ui-static/custom_theme/oe-black-1080p.png)",
                        "--image-header-logo": "url(/ui-static/custom_theme/oe-black-header.svg)",
                        "--image-launcher-logo": "url(/ui-static/custom_theme/oe-black-1080p.png)"
                    }
                },
                {
                    "name": "dark",
                    "vars": {
                        "--image-large-logo": "url(/ui-static/custom_theme/oe-white-1080p.png)",
                        "--image-header-logo": "url(/ui-static/custom_theme/oe-white-header.svg)",
                        "--image-launcher-logo": "url(/ui-static/custom_theme/oe-white-1080p.png)"
                    }
                }
            ]
        }

        # Update menu
        config_dict["menu"] = {
            "disabled_items": [
                "cases",
                "relations",
                "video-wall",
                "video_wall",
                "clusters",
                "audit-logs",
                "reports",
                "sessions",
                "documentation",
                "api-docs",
                "api_doc",
                "alarm",
                "counters",
                "license",
                "Alert",
                "player",
                "analytics",
                "blocklistRecords",
                "interface",
                "alarms",
                "alarmMonitor",
                "alarm_app",
                "verify",
                "license",
                "alertmanager",
                "alerts",
                "alert-rules",
                "lines",
                "areas"
            ]
        }

        # Update languages
        config_dict["languages"] = {
            "select-language": False,
            "items": [
                {
                    "name": "en",
                    "label": "English",
                    "url": "/ui-static/i18n/en_ffmulti.po"
                }
            ]
        }

        # Format and write
        formatted_config = "FFSECURITY_UI_CONFIG = " + pprint.pformat(config_dict, indent=4) + "\n"
        updated_lines = lines[:config_start] + [formatted_config] + lines[config_end+1:]

        with open(file_path, 'w') as file:
            file.writelines(updated_lines)

        print("FFSECURITY_UI_CONFIG updated successfully")
        return True
    except Exception as e:
        print(f"Error updating FindFace config: {e}")
        return False

if __name__ == "__main__":
    success = update_findface_config(sys.argv[1])
    sys.exit(0 if success else 1)
EOF

    if python3 "$temp_script" "$config_path"; then
        print_success "FindFace configuration updated"
        rm -f "$temp_script"
    else
        print_error "Failed to update FindFace configuration"
        rm -f "$temp_script"
        return 1
    fi
}

# Main execution function
main() {
    print_step "Starting Complete OE Setup Process"
    echo "This script will:"
    echo "1. Run all OE checklist scripts (cleanup)"
    echo "3. Restart Docker services"
    echo ""
    
    # Get the directory where this script is located
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    
    # Define paths
    DOCKER_COMPOSE_PATH="/opt/oe/docker-compose.yaml"
    FINDFACE_CONFIG_PATH="/opt/oe/configs/oe-legacy/oe-legacy.py"
    CUSTOM_THEME_FOLDER="/opt/oe/data/custom_theme"
    BLANK_WATERMARK_PATH="$CUSTOM_THEME_FOLDER/blank.svg"
    
    # Verify required directories exist
    if [ ! -d "/opt/oe" ]; then
        print_error "/opt/oe directory does not exist!"
        exit 1
    fi
    
    # Phase 1: Run OE checklist scripts
    print_step "Phase 1: Running OE Checklist Scripts"
    
    # Ensure Tarantool shard directories exist (fix for the storage issue)
    print_status "Ensuring Tarantool shard directories exist..."
    for shard in {001..012}; do
        shard_dir="/opt/oe/data/oe-tarantool-server/shard-$shard"
        # Create the shard directory and subdirectories if they don't exist
        sudo mkdir -p "$shard_dir"/{snapshots,xlogs,index} 2>/dev/null || true
        print_status "Created/verified shard-$shard directories"
    done
    print_success "Tarantool shard directories verified"
    
    # Fix upload directory permissions for face detection storage
    print_status "Fixing upload directory permissions..."
    if [ -d "/opt/oe/data/oe-upload/uploads" ]; then
        sudo chmod -R 777 /opt/oe/data/oe-upload/uploads/ 2>/dev/null || true
        print_success "Upload directory permissions fixed"
    else
        print_status "Upload directory not found, will be created by Docker"
    fi
    
    # Array of scripts to run in order
    declare -a scripts=(
        "$SCRIPT_DIR/deleteAlarm.sh"
        "$SCRIPT_DIR/deleteModels.sh"
        "$SCRIPT_DIR/renameAudit.sh"
        "$SCRIPT_DIR/renameCleanerService.sh"
        "$SCRIPT_DIR/renameCounter.sh"
        "$SCRIPT_DIR/renameExtractionApi.sh"
        "$SCRIPT_DIR/renameFileMover.sh"
        "$SCRIPT_DIR/renameIdentityProvider.sh"
        "$SCRIPT_DIR/renameImagecrop.sh"
        "$SCRIPT_DIR/renameLicenseServer.sh"
        "$SCRIPT_DIR/renameLiveness.sh"
        "$SCRIPT_DIR/renameMultiLegacy.sh"
        "$SCRIPT_DIR/renameOnvifDiscovery.sh"
        "$SCRIPT_DIR/renameSfapi.sh"
        "$SCRIPT_DIR/renameSingletonService.sh"
        "$SCRIPT_DIR/renameStreamManager.sh"
        "$SCRIPT_DIR/renameStreamWorker.sh"
        "$SCRIPT_DIR/renameTarantoolServer.sh"
        "$SCRIPT_DIR/renameUI.sh"
        "$SCRIPT_DIR/renameUploadServer.sh"
    )
    
    # Count total scripts
    total_scripts=${#scripts[@]}
    current_script=0
    failed_scripts=()
    
    # Run each script
    for script in "${scripts[@]}"; do
        current_script=$((current_script + 1))
        echo ""
        print_status "Progress: $current_script/$total_scripts"
        echo "-------------------------------------------------------"
        
        if ! run_script "$script"; then
            failed_scripts+=("$(basename "$script")")
            print_warning "Continuing with next script..."
        fi
    done
    
    echo ""
    print_success "OE checklist scripts completed!"
    
    # Report failed scripts if any
    if [ ${#failed_scripts[@]} -gt 0 ]; then
        print_warning "The following scripts failed:"
        for failed_script in "${failed_scripts[@]}"; do
            echo "  - $failed_script"
        done
        echo ""
    fi
    
    # Phase 2: Apply custom branding
    print_step "Phase 2: Applying Custom OptiExacta Branding"
    
    # Install Python dependencies
    install_python_dependencies
    
    # Download custom theme files
    download_custom_theme "$CUSTOM_THEME_FOLDER"
    
    # Create blank watermark
    create_blank_watermark "$BLANK_WATERMARK_PATH"
    
    # Check if required files exist
    if [ ! -f "$DOCKER_COMPOSE_PATH" ]; then
        print_error "Docker Compose file not found: $DOCKER_COMPOSE_PATH"
        exit 1
    fi
    
    if [ ! -f "$FINDFACE_CONFIG_PATH" ]; then
        print_error "FindFace config file not found: $FINDFACE_CONFIG_PATH"
        exit 1
    fi
    
    # Update Docker Compose configuration
    update_docker_compose_with_python "$DOCKER_COMPOSE_PATH" "$CUSTOM_THEME_FOLDER" "$BLANK_WATERMARK_PATH"
    
    # Update FindFace configuration
    update_findface_config "$FINDFACE_CONFIG_PATH"
    
    # Phase 3: Restart Docker services
    print_step "Phase 3: Restarting Docker Services"
    
    # Change to /opt/oe directory
    cd /opt/oe || {
        print_error "Failed to change to /opt/oe directory"
        exit 1
    }
    
    # Stop docker-compose services
    print_status "Stopping Docker Compose services..."
    if sudo docker-compose down; then
        print_success "Docker Compose services stopped successfully"
    else
        print_error "Failed to stop Docker Compose services"
        exit 1
    fi
    
    # Start docker-compose services
    print_status "Starting Docker Compose services in detached mode..."
    if sudo docker-compose up -d; then
        print_success "Docker Compose services started successfully"
    else
        print_error "Failed to start Docker Compose services"
        exit 1
    fi
    
    # Wait for services to initialize
    print_status "Waiting for services to initialize..."
    sleep 10
    
    # Fix upload directory permissions after Docker start (sometimes reset by containers)
    print_status "Re-applying upload directory permissions after Docker start..."
    if [ -d "/opt/oe/data/oe-upload/uploads" ]; then
        sudo chmod -R 777 /opt/oe/data/oe-upload/uploads/ 2>/dev/null || true
        print_success "Upload directory permissions re-applied"
    fi
    
    # Final summary
    print_step "Setup Complete!"
    echo ""
    print_success "All operations completed successfully!"
    
    if [ ${#failed_scripts[@]} -eq 0 ]; then
        print_success "All OE checklist scripts ran without errors"
    else
        print_warning "${#failed_scripts[@]} script(s) failed during OE checklist phase"
    fi
    
    print_success "Custom checklist applied successfully"
    print_success "Docker services restarted successfully"
    
    # Post-setup verification
    print_step "Post-Setup Verification"
    
    # Check if key services are running
    print_status "Verifying key services are running..."
    
    # Check upload service
    if sudo docker ps | grep -q "oe-oe-upload-1.*Up"; then
        print_success "Upload service is running"
    else
        print_warning "Upload service may not be running properly"
    fi
    
    # Check legacy service
    if sudo docker ps | grep -q "oe-oe-legacy-1.*Up.*healthy"; then
        print_success "Legacy service is running and healthy"
    else
        print_warning "Legacy service may not be healthy"
    fi
    
    # Check stream worker
    if sudo docker ps | grep -q "oe-oe-stream-worker-1.*Up"; then
        print_success "Stream worker is running"
    else
        print_warning "Stream worker may not be running properly"
    fi
    
    print_status "System verification completed"
    
    echo ""
    echo "Your OptiExacta system is now ready with:"
    echo "• Clean configuration"
    echo "• Disabled unnecessary menu items"
    echo ""
    print_success "Setup completed successfully!"
    
    echo "============================================================="
}

# Check if running as root (needed for some operations)
if [ "$EUID" -eq 0 ]; then
    print_warning "Running as root. Some operations may require sudo anyway."
fi

# Run main function
main "$@"

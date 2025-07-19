#!/bin/bash

# Master script to run all OE checklist scripts and restart docker services
# Created on July 14, 2025

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

# Main execution
main() {
    print_status "Starting OE checklist script execution..."
    echo "======================================================="
    
    # Get the directory where this script is located
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    
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
    echo "======================================================="
    print_status "All scripts execution completed!"
    
    # Report failed scripts if any
    if [ ${#failed_scripts[@]} -gt 0 ]; then
        print_warning "The following scripts failed:"
        for failed_script in "${failed_scripts[@]}"; do
            echo "  - $failed_script"
        done
        echo ""
    fi
    
    # Docker compose operations
    print_status "Starting Docker Compose operations..."
    echo "-------------------------------------------------------"
    
    # Check if /opt/oe directory exists
    if [ ! -d "/opt/oe" ]; then
        print_error "/opt/oe directory does not exist!"
        print_error "Please ensure the directory exists before running docker-compose commands."
        exit 1
    fi
    
    # Change to /opt/oe directory
    cd /opt/oe
    print_status "Changed to /opt/oe directory"
    
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
    
    echo ""
    echo "======================================================="
    print_success "All operations completed successfully!"
    
    if [ ${#failed_scripts[@]} -eq 0 ]; then
        print_success "All scripts ran without errors"
    else
        print_warning "${#failed_scripts[@]} script(s) failed - please check the output above"
    fi
    
    print_success "Docker services have been restarted"
    
    echo "======================================================="
}

# Run main function
main "$@"

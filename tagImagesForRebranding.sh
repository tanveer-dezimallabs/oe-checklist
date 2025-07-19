#!/bin/bash

# Script to tag existing ntech images with optiexacta names
# This allows the rebranded docker-compose.yaml to work with existing images

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

print_status "Starting image tagging process for rebranding..."

# Get all ntech images and tag them with optiexacta names
print_status "Tagging ntech images with optiexacta names..."

# Tag multi images
docker tag docker.int.ntl/ntech/multi/multi/ui:ffmulti-2.1.3.5 docker.int.ntl/optiexacta/multi/multi/ui:ffmulti-2.1.3.5
docker tag docker.int.ntl/ntech/multi/multi/legacy:ffmulti-2.1.3.5 docker.int.ntl/optiexacta/multi/multi/legacy:ffmulti-2.1.3.5
docker tag docker.int.ntl/ntech/multi/multi/identity-provider:ffmulti-2.1.3.5 docker.int.ntl/optiexacta/multi/multi/identity-provider:ffmulti-2.1.3.5
docker tag docker.int.ntl/ntech/multi/multi/audit:ffmulti-2.1.3.5 docker.int.ntl/optiexacta/multi/multi/audit:ffmulti-2.1.3.5
docker tag docker.int.ntl/ntech/multi/multi/file-mover:ffmulti-2.1.3.5 docker.int.ntl/optiexacta/multi/multi/file-mover:ffmulti-2.1.3.5

# Tag universe images
docker tag docker.int.ntl/ntech/universe/liveness-api:ffserver-9.230407.1 docker.int.ntl/optiexacta/universe/liveness-api:ffserver-9.230407.1
docker tag docker.int.ntl/ntech/universe/counter:ffserver-9.230407.1 docker.int.ntl/optiexacta/universe/counter:ffserver-9.230407.1
docker tag docker.int.ntl/ntech/universe/video-worker-cpu:ffserver-9.230407.1 docker.int.ntl/optiexacta/universe/video-worker-cpu:ffserver-9.230407.1
docker tag docker.int.ntl/ntech/universe/video-manager:ffserver-9.230407.1 docker.int.ntl/optiexacta/universe/video-manager:ffserver-9.230407.1
docker tag docker.int.ntl/ntech/universe/sf-api:ffserver-9.230407.1 docker.int.ntl/optiexacta/universe/sf-api:ffserver-9.230407.1
docker tag docker.int.ntl/ntech/universe/extraction-api-cpu:ffserver-9.230407.1 docker.int.ntl/optiexacta/universe/extraction-api-cpu:ffserver-9.230407.1
docker tag docker.int.ntl/ntech/universe/upload:ffserver-9.230407.1 docker.int.ntl/optiexacta/universe/upload:ffserver-9.230407.1
docker tag docker.int.ntl/ntech/universe/tntapi:ffserver-9.230407.1 docker.int.ntl/optiexacta/universe/tntapi:ffserver-9.230407.1
docker tag docker.int.ntl/ntech/universe/ntls:ffserver-9.230407.1 docker.int.ntl/optiexacta/universe/ntls:ffserver-9.230407.1

print_success "Image tagging completed"

# Show the tagged images
print_status "Verifying tagged images:"
docker images | grep optiexacta

print_success "All images have been tagged with optiexacta names"
print_status "Now you can run: sudo docker-compose up -d"

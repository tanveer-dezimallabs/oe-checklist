#!/bin/bash
set -e

# Directories to check for models
MODEL_DIRS=(
    "/opt/oe/models"
    "/opt/oe/data"
)

# List of model subdirectories or files to remove
UNUSED_MODELS=(
    "carattr"
    "carnorm"
    "carrec"
    "pedattr"
    "pedrec"
)

for dir in "${MODEL_DIRS[@]}"; do
    for model in "${UNUSED_MODELS[@]}"; do
        if [ -d "$dir/$model" ]; then
            rm -rf "$dir/$model"
            echo "Removed directory: $dir/$model"
        elif [ -f "$dir/$model" ]; then
            rm -f "$dir/$model"
            echo "Removed file: $dir/$model"
        fi
    done
done

echo "Unnecessary non-face detector models have been removed from all relevant locations."

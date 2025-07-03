#!/bin/bash
set -e

MODELS_DIR="./models"

# List of model subdirectories or files to remove
UNUSED_MODELS=(
    "carattr"
    "carnorm"
    "carrec"
    "pedattr"
    "pedrec"
)

for model in "${UNUSED_MODELS[@]}"; do
    if [ -d "$MODELS_DIR/$model" ]; then
        rm -rf "$MODELS_DIR/$model"
        echo "Removed directory: $MODELS_DIR/$model"
    elif [ -f "$MODELS_DIR/$model" ]; then
        rm -f "$MODELS_DIR/$model"
        echo "Removed file: $MODELS_DIR/$model"
    fi
done

echo "Unnecessary non-face models have been removed."

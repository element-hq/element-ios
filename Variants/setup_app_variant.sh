#!/bin/bash

# If you want to use an existing build variant or your own one you have to choose or create a folder with your variant name in "Variants" folder.

if [ ! $# -eq 1 ]; then
    echo "Usage: ./setup_app_variant.sh [variant folder name]"
    exit 1
fi

# Get variant name from user input
VARIANT_NAME=$1
VARIANTS_ROOT_FOLDER="Variants/"

cd ..

# Get the variant root folder
variant_root_folder="${VARIANTS_ROOT_FOLDER}${VARIANT_NAME}/"

project_root_folder="./"

# Check if variant folder exists
if [ ! -d "$variant_root_folder" ]; then
    echo "Variant folder: ${variant_root_folder} do not exists"
    exit 1
fi

echo "Applying app variant: ${VARIANT_NAME}"

# Merge variant directory into project directory
rsync -a "${variant_root_folder}" "${project_root_folder}"

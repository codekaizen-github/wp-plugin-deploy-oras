#!/bin/bash
set -e
set -x

# Required ENV variables:
#   PLUGIN_SLUG: Unique slug for the plugin (e.g. wp-github-gist-block)
#   PLUGIN_ZIP_PATH: Path to the plugin zip file
#   ANNOTATION_PREFIX: Prefix for annotation keys (default: org.codekaizen-github.wp-plugin-deploy-oras)
#   REGISTRY_USERNAME: Registry username
#   REGISTRY_PASSWORD: Registry password
#   IMAGE_NAME: Image name (e.g. ghcr.io/codekaizen-github/wp-github-gist-block:v1)

ANNOTATION_PREFIX="${ANNOTATION_PREFIX:-org.codekaizen-github.wp-plugin-deploy-oras}"

if [ -z "$PLUGIN_ZIP_PATH" ]; then
    echo "PLUGIN_ZIP_PATH env variable is required!" >&2
    exit 1
fi
if [ -z "$REGISTRY_USERNAME" ]; then
    echo "REGISTRY_USERNAME env variable is required!" >&2
    exit 1
fi
if [ -z "$REGISTRY_PASSWORD" ]; then
    echo "REGISTRY_PASSWORD env variable is required!" >&2
    exit 1
fi
if [ -z "$IMAGE_NAME" ]; then
    echo "IMAGE_NAME env variable is required!" >&2
    exit 1
fi

# Get the directory of this script for relative references
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Parse plugin metadata using wp-package-parser script
PLUGIN_METADATA=$(php -d memory_limit="${PHP_MEMORY_LIMIT:-512M}" "$SCRIPT_DIR/src/get_plugin_metadata.php" "$PLUGIN_ZIP_PATH")

# Login to registry
oras login --username "$REGISTRY_USERNAME" --password "$REGISTRY_PASSWORD" "$(echo "$IMAGE_NAME" | cut -d'/' -f1)"

# Get directory and filename from PLUGIN_ZIP_PATH
PLUGIN_ZIP_DIR="$(dirname "$PLUGIN_ZIP_PATH")"
PLUGIN_ZIP_FILE="$(basename "$PLUGIN_ZIP_PATH")"

# Change to the directory containing the zip file
pushd "$PLUGIN_ZIP_DIR" >/dev/null

# Push the zip file with annotations using only the filename (relative path)
oras push "$IMAGE_NAME" \
    "${PLUGIN_ZIP_FILE}:application/zip" \
    --annotation "$ANNOTATION_PREFIX.wp-plugin-metadata=$PLUGIN_METADATA"

popd >/dev/null

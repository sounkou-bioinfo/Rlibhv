#!/bin/bash
# Download and extract c-ares sources
set -euo pipefail

# Define version
version=1.24.0  # Latest stable version as of June 2025
DOWNLOAD_DIR="$(dirname "$0")/src"
CARES_DIR="$DOWNLOAD_DIR/c-ares"

echo "Downloading c-ares version ${version} from GitHub"

# Create download directory if it doesn't exist
mkdir -p "$DOWNLOAD_DIR"
cd "$DOWNLOAD_DIR" || exit 1

# Download using curl
curl -L "https://github.com/c-ares/c-ares/releases/download/cares-${version//./_}/c-ares-${version}.tar.gz" -o "c-ares-${version}.tar.gz"

# Remove existing c-ares directory if it exists
if [ -d "c-ares" ]; then
    rm -rf c-ares
fi

# Extract the tarball
echo "Unpacking c-ares version ${version}"
tar -xzf "c-ares-${version}.tar.gz"

# Rename the extracted directory to just "c-ares"
mv "c-ares-${version}" c-ares

# Clean up the tarball
echo "Cleaning up"
rm -f "c-ares-${version}.tar.gz"

echo "c-ares sources successfully downloaded to $CARES_DIR"

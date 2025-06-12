#!/bin/bash
# Download and extract nghttp2 sources
set -euo pipefail

# Define version
version=1.65.0
DOWNLOAD_DIR="$(dirname "$0")/src"
NGHTTP2_DIR="$DOWNLOAD_DIR/nghttp2"

echo "Downloading nghttp2 version ${version} from GitHub"

# Create download directory if it doesn't exist
mkdir -p "$DOWNLOAD_DIR"
cd "$DOWNLOAD_DIR" || exit 1

# Download using curl
curl -L "https://github.com/nghttp2/nghttp2/releases/download/v${version}/nghttp2-${version}.tar.gz" -o "nghttp2-${version}.tar.gz"

# Remove existing nghttp2 directory if it exists
if [ -d "nghttp2" ]; then
    rm -rf nghttp2
fi

# Extract the tarball
echo "Unpacking nghttp2 version ${version}"
tar -xzf "nghttp2-${version}.tar.gz"

# Rename the extracted directory to just "nghttp2"
mv "nghttp2-${version}" nghttp2

# Clean up the tarball
echo "Cleaning up"
rm -f "nghttp2-${version}.tar.gz"

echo "nghttp2 sources successfully downloaded to $NGHTTP2_DIR"

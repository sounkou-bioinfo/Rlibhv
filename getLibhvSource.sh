#!/bin/bash
# Download and extract libhv sources
set -euo pipefail

# Define version
version=1.3.3
DOWNLOAD_DIR="$(dirname "$0")/src"
LIBHV_DIR="$DOWNLOAD_DIR/libhv"

echo "Downloading libhv version ${version} from GitHub"

# Create download directory if it doesn't exist
mkdir -p "$DOWNLOAD_DIR"
cd "$DOWNLOAD_DIR" || exit 1

# Download using curl (more widely available than wget)
curl -L "https://github.com/ithewei/libhv/archive/refs/tags/v${version}.tar.gz" -o "v${version}.tar.gz"

# Remove existing libhv directory if it exists
if [ -d "libhv" ]; then
    rm -rf libhv
fi

# Extract the tarball
echo "Unpacking libhv version ${version}"
tar -xzf "v${version}.tar.gz"

# Rename the extracted directory to just "libhv"
mv "libhv-${version}" libhv

# Clean up the tarball
echo "Cleaning up"
rm -f "v${version}.tar.gz"

echo "libhv sources successfully downloaded to $LIBHV_DIR"
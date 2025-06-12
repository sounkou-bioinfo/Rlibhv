#!/bin/bash
# Download and extract libev sources
set -euo pipefail

# Define version
version=4.33
DOWNLOAD_DIR="$(dirname "$0")/src"
LIBEV_DIR="$DOWNLOAD_DIR/libev"
#http://dist.schmorp.de/libev/libev-4.33.tar.gz
echo "Downloading libev version ${version} from http://dist.schmorp.de/libev/libev-${version}.tar.gz"

# Create download directory if it doesn't exist
mkdir -p "$DOWNLOAD_DIR"
cd "$DOWNLOAD_DIR" || exit 1

# Download using curl (more widely available than wget)
curl -L http://dist.schmorp.de/libev/libev-${version}.tar.gz -o "libev-${version}.tar.gz"

# Remove existing libev directory if it exists
if [ -d "libev" ]; then
    rm -rf libev
fi

# Extract the tarball
echo "Unpacking libev from http://dist.schmorp.de/libev/Attic/libev-${version}.tar.gz"
tar -xzf "libev-${version}.tar.gz"

# Rename the extracted directory to just "libev"
mv "libev-${version}" libev

# Clean up the tarball
echo "Cleaning up"
rm -f "libev-${version}.tar.gz"

echo "libev sources successfully downloaded to $LIBEV_DIR"

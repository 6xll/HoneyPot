#!/bin/bash
# Cowrie Entrypoint Script
# This script initializes the Cowrie environment by copying required data files
# from the source directory to the share directory for compatibility

set -e

echo "🍯 Cowrie Honeypot Initialization"
echo "=================================="

# Define source and destination paths
SOURCE_DATA_DIR="/cowrie/cowrie-git/src/cowrie/data"
DEST_SHARE_DIR="/cowrie/cowrie-git/share/cowrie"

# Create share directory structure if it doesn't exist
echo "📁 Creating share directory structure..."
mkdir -p "${DEST_SHARE_DIR}"
mkdir -p "${DEST_SHARE_DIR}/txtcmds"

# Copy cmdoutput.json if it doesn't exist or source is newer
if [ ! -f "${DEST_SHARE_DIR}/cmdoutput.json" ] || [ "${SOURCE_DATA_DIR}/cmdoutput.json" -nt "${DEST_SHARE_DIR}/cmdoutput.json" ]; then
    echo "📋 Copying cmdoutput.json..."
    cp -f "${SOURCE_DATA_DIR}/cmdoutput.json" "${DEST_SHARE_DIR}/cmdoutput.json"
    echo "✅ cmdoutput.json copied successfully"
else
    echo "✅ cmdoutput.json already exists and is up to date"
fi

# Copy fs.pickle if it doesn't exist or source is newer
if [ ! -f "${DEST_SHARE_DIR}/fs.pickle" ] || [ "${SOURCE_DATA_DIR}/fs.pickle" -nt "${DEST_SHARE_DIR}/fs.pickle" ]; then
    echo "📦 Copying fs.pickle..."
    cp -f "${SOURCE_DATA_DIR}/fs.pickle" "${DEST_SHARE_DIR}/fs.pickle"
    echo "✅ fs.pickle copied successfully"
else
    echo "✅ fs.pickle already exists and is up to date"
fi

# Copy txtcmds directory if it doesn't exist or source is newer
if [ ! -d "${DEST_SHARE_DIR}/txtcmds/bin" ] || [ "${SOURCE_DATA_DIR}/txtcmds" -nt "${DEST_SHARE_DIR}/txtcmds" ]; then
    echo "📂 Copying txtcmds directory..."
    cp -rf "${SOURCE_DATA_DIR}/txtcmds" "${DEST_SHARE_DIR}/"
    echo "✅ txtcmds directory copied successfully"
else
    echo "✅ txtcmds directory already exists and is up to date"
fi

# Copy arch directory if it exists and destination doesn't exist
if [ -d "${SOURCE_DATA_DIR}/arch" ] && [ ! -d "${DEST_SHARE_DIR}/arch" ]; then
    echo "🏗️ Copying arch directory..."
    cp -rf "${SOURCE_DATA_DIR}/arch" "${DEST_SHARE_DIR}/"
    echo "✅ arch directory copied successfully"
fi

# Copy pool_configs directory if it exists and destination doesn't exist
if [ -d "${SOURCE_DATA_DIR}/pool_configs" ] && [ ! -d "${DEST_SHARE_DIR}/pool_configs" ]; then
    echo "🏊 Copying pool_configs directory..."
    cp -rf "${SOURCE_DATA_DIR}/pool_configs" "${DEST_SHARE_DIR}/"
    echo "✅ pool_configs directory copied successfully"
fi

echo ""
echo "✅ Initialization complete!"
echo ""
echo "📊 Files in ${DEST_SHARE_DIR}:"
ls -lh "${DEST_SHARE_DIR}/"
echo ""

# Execute the original cowrie command
echo "🚀 Starting Cowrie..."
echo ""
exec "$@"

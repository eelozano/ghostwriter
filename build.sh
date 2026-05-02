#!/bin/bash
set -e

APP_NAME="Ghostwriter"
APP_BUNDLE="${APP_NAME}.app"
MACOS_DIR="${APP_BUNDLE}/Contents/MacOS"
RESOURCES_DIR="${APP_BUNDLE}/Contents/Resources"

echo "Building ${APP_NAME}..."

# Create app bundle structure
mkdir -p "${MACOS_DIR}"
mkdir -p "${RESOURCES_DIR}"

# Copy Info.plist
cp Info.plist "${APP_BUNDLE}/Contents/"

# Find all Swift files
SWIFT_FILES=$(find Sources -name "*.swift")

if [ -z "$SWIFT_FILES" ]; then
  echo "No Swift files found in Sources directory."
  exit 1
fi

# Compile Swift files
swiftc -o "${MACOS_DIR}/${APP_NAME}" $SWIFT_FILES

# Create a sample icon (optional)
# Using a generic system icon for now if needed

echo "Build successful: ${APP_BUNDLE}"

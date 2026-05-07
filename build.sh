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

# Compile Swift files for macOS 12.0 (Universal Binary)
swiftc -o "${MACOS_DIR}/${APP_NAME}" $SWIFT_FILES -target arm64-apple-macosx12.0 -target x86_64-apple-macosx12.0

# Copy Assets to Resources
if [ -d "Assets" ]; then
    cp -R Assets/* "${RESOURCES_DIR}/"
fi

# Force macOS to recognize the new icon
touch "${APP_BUNDLE}"

echo "Build successful: ${APP_BUNDLE}"

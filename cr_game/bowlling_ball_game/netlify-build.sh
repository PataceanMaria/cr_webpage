#!/bin/bash
set -e

# Install Flutter
echo "Installing Flutter..."
FLUTTER_VERSION="3.24.5"
curl -L "https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_${FLUTTER_VERSION}-stable.tar.xz" | tar xJ
export PATH="$PWD/flutter/bin:$PATH"

# Configure Flutter
flutter config --no-analytics
flutter doctor

# Get dependencies
echo "Getting Flutter dependencies..."
flutter pub get

# Build web app
echo "Building Flutter web app..."
flutter build web --release

# Copy SEO files
echo "Copying SEO files..."
cp robots.txt sitemap.xml build/web/ 2>/dev/null || true

echo "Build complete!"


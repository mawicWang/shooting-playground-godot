#!/bin/bash

# Godot Web Export Script for macOS
# This script exports the Godot project to HTML5 and updates the web directory

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
PROJECT_NAME="shooting-playground-godot"
WEB_DIR="web"
EXPORT_PRESET="Web"
GODOT_CMD="godot"

# Function to print colored messages
print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if running on macOS
if [[ "$OSTYPE" != "darwin"* ]]; then
    print_warn "This script is designed for macOS, but continuing anyway..."
fi

# Check if Godot is installed
if ! command -v "$GODOT_CMD" &> /dev/null; then
    print_error "Godot is not installed or not in PATH"
    print_info "Please install Godot or add it to your PATH"
    exit 1
fi

print_info "Godot found: $($GODOT_CMD --version)"

# Check if export_presets.cfg exists
if [ ! -f "export_presets.cfg" ]; then
    print_error "export_presets.cfg not found in current directory"
    print_info "Please run this script from the project root directory"
    exit 1
fi

# Check if Web preset exists
if ! grep -q "\[preset.0\]" export_presets.cfg || ! grep -q 'name="Web"' export_presets.cfg; then
    print_error "Web export preset not found in export_presets.cfg"
    print_info "Please configure a Web export preset in Godot first"
    exit 1
fi

# Create web directory if it doesn't exist
if [ ! -d "$WEB_DIR" ]; then
    print_info "Creating $WEB_DIR directory..."
    mkdir -p "$WEB_DIR"
fi

# Backup existing index.html
if [ -f "$WEB_DIR/index.html" ]; then
    print_info "Backing up existing index.html..."
    cp "$WEB_DIR/index.html" "$WEB_DIR/index.html.backup.$(date +%Y%m%d_%H%M%S)"
fi

# Clean old export files (preserve .gitignore and coi-serviceworker.js)
print_info "Cleaning old export files..."
find "$WEB_DIR" -name "index.*" -type f ! -name "*.import" -delete 2>/dev/null || true

# Export the project
print_info "Exporting Godot project to HTML5..."
print_info "This may take a while..."

$GODOT_CMD --headless --export-release "$EXPORT_PRESET" "$WEB_DIR/index.html"

# Check if export was successful
if [ ! -f "$WEB_DIR/index.html" ]; then
    print_error "Export failed: index.html not created"
    exit 1
fi

# Check for required files
REQUIRED_FILES=("index.js" "index.wasm" "index.pck")
for file in "${REQUIRED_FILES[@]}"; do
    if [ ! -f "$WEB_DIR/$file" ]; then
        print_error "Export incomplete: $file not found"
        exit 1
    fi
done

# Get file sizes for info
PCK_SIZE=$(ls -lh "$WEB_DIR/index.pck" | awk '{print $5}')
WASM_SIZE=$(ls -lh "$WEB_DIR/index.wasm" | awk '{print $5}')

print_info "Export completed successfully!"
print_info "Files generated in $WEB_DIR/:"
print_info "  - index.html (main HTML file)"
print_info "  - index.js (JavaScript runtime)"
print_info "  - index.wasm ($WASM_SIZE - WebAssembly binary)"
print_info "  - index.pck ($PCK_SIZE - game data)"
print_info "  - index.png (splash image)"
print_info "  - index.icon.png (favicon)"

print_info "Build complete! You can now deploy the $WEB_DIR/ directory to your web server."
print_info "To test locally, run: python3 -m http.server 8080 --directory $WEB_DIR"

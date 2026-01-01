#!/bin/bash

# Script copied from /usr/local/bin/auto-install-appimages.sh
# Linted and adjusted by assistant

set -euo pipefail
IFS=$'\n\t'

# Original script content

#!/bin/bash

# Script to automatically install all AppImages in ~/Applications folder
# Checks if they already have desktop entries and only installs if missing
# Usage: auto-install-appimages.sh [--force|-f]

# Check for force flag
FORCE_INSTALL=false
if [ "$1" = "--force" ] || [ "$1" = "-f" ]; then
    FORCE_INSTALL=true
fi

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

APPLICATIONS_DIR=~/Applications
DESKTOP_DIR=~/.local/share/applications
PIXMAPS_DIR=~/.local/share/pixmaps

echo -e "${BLUE}╔════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║  AppImage Auto-Installer               ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════╝${NC}"
echo ""

if [ "$FORCE_INSTALL" = true ]; then
    echo -e "${YELLOW}Force mode enabled - will reinstall all AppImages${NC}"
    echo ""
fi

# Create directories if they don't exist
mkdir -p "$APPLICATIONS_DIR"
mkdir -p "$DESKTOP_DIR"
mkdir -p "$PIXMAPS_DIR"

# Check if Applications directory exists and has AppImages
if [ ! -d "$APPLICATIONS_DIR" ]; then
    echo -e "${RED}Error: $APPLICATIONS_DIR does not exist${NC}"
    exit 1
fi

# Find all AppImages
mapfile -t APPIMAGES < <(find "$APPLICATIONS_DIR" -maxdepth 1 -type f -name "*.AppImage" -print)

if [ ${#APPIMAGES[@]} -eq 0 ]; then
    echo -e "${YELLOW}No AppImages found in $APPLICATIONS_DIR${NC}"
    exit 0
fi

echo -e "${BLUE}Found ${#APPIMAGES[@]} AppImage(s) in $APPLICATIONS_DIR${NC}"
echo ""

# Function to extract app name from filename
get_app_name() {
    local filename
    filename=$(basename "$1" .AppImage)

    # Try to extract a clean name from common naming patterns
    # Remove version numbers, architecture, OS info, etc.
    local name
    name=$(echo "$filename" | sed -E 's/[_-]v?[0-9]+(\.[0-9]+)*.*$//I' | sed -E 's/[_-](x86|x64|64bit|linux|ubuntu).*//I' | sed 's/_/ /g' | sed 's/-/ /g')

    echo "$name"
}

# Function to get identifier for desktop file naming
get_identifier() {
    local app_name="$1"
    echo "$app_name" | tr '[:upper:]' '[:lower:]' | tr ' ' '-' | sed 's/[^a-z0-9-]//g'
}

# Function to check if desktop entry already exists
desktop_entry_exists() {
    local appimage_path="$1"
    local identifier="$2"
    
    # Check if a desktop file with this identifier exists
    if [ -f "$DESKTOP_DIR/${identifier}.desktop" ]; then
        # Check if it points to this AppImage
        if grep -q "$appimage_path" "$DESKTOP_DIR/${identifier}.desktop" 2>/dev/null; then
            return 0
        fi
    fi
    
    # Also check if any desktop file points to this AppImage
    if grep -l "Exec=$appimage_path" "$DESKTOP_DIR"/*.desktop 2>/dev/null | grep -q .; then
        return 0
    fi
    
    return 1
}

# Function to guess categories based on app name
guess_categories() {
    local name="$1"
    local lower_name
    lower_name=$(echo "$name" | tr '[:upper:]' '[:lower:]')
    
    case "$lower_name" in
        *slicer*|*orca*|*prusa*|*cura*)
            echo "Graphics;3DGraphics;Engineering"
            ;;
        *freecad*|*blender*|*openscad*)
            echo "Graphics;Engineering;3DGraphics"
            ;;
        *arduino*|*platformio*)
            echo "Development;Electronics;Engineering"
            ;;
        *gimp*|*krita*|*inkscape*)
            echo "Graphics;2DGraphics"
            ;;
        *kdenlive*|*obs*|*shotcut*)
            echo "AudioVideo;Video;VideoEditing"
            ;;
        *audacity*|*sonic*)
            echo "AudioVideo;Audio;AudioEditing"
            ;;
        *code*|*atom*|*sublime*)
            echo "Development;IDE"
            ;;
        *)
            echo "Utility"
            ;;
    esac
}

# Function to install an AppImage
install_appimage() {
    local appimage_path="$1"
    local app_name="$2"
    local identifier="$3"
    
    echo -e "${GREEN}Installing:   $app_name${NC}"
    
    # Make sure it's executable
    chmod +x "$appimage_path"
    
    # Extract AppImage to get icon
    echo "  → Extracting AppImage..."
    TEMP_DIR=$(mktemp -d)
    cd "$TEMP_DIR" || { echo "Failed to enter temp dir $TEMP_DIR"; exit 1; }
    
    # Try to extract (some AppImages might fail, handle gracefully)
    if "$appimage_path" --appimage-extract > /dev/null 2>&1; then
        
        # Find icon
        ICON_FOUND=false
        ICON_PATH=""
        
        # Try multiple search strategies
        # 1. Look in standard icon directories
        for size in 256 192 128 96 64 48; do
            icon=$(find squashfs-root -path "*/icons/hicolor/${size}x${size}/*" -type f \( -name "*.png" -o -name "*.svg" \) 2>/dev/null | head -1)
            if [ -n "$icon" ] && [ -f "$icon" ]; then
                ICON_PATH="$icon"
                ICON_FOUND=true
                break
            fi
        done
        
        # 2. Look for any PNG in icon directories
        if [ "$ICON_FOUND" = false ]; then
            icon=$(find squashfs-root -type f -path "*/icons/*" -name "*.png" 2>/dev/null | head -1)
            if [ -n "$icon" ] && [ -f "$icon" ]; then
                ICON_PATH="$icon"
                ICON_FOUND=true
            fi
        fi
        
        # 3. Look for SVG
        if [ "$ICON_FOUND" = false ]; then
            icon=$(find squashfs-root -type f -name "*.svg" 2>/dev/null | head -1)
            if [ -n "$icon" ] && [ -f "$icon" ]; then
                ICON_PATH="$icon"
                ICON_FOUND=true
            fi
        fi
        
        # 4. Look for any PNG
        if [ "$ICON_FOUND" = false ]; then
            icon=$(find squashfs-root -type f -name "*.png" 2>/dev/null | head -1)
            if [ -n "$icon" ] && [ -f "$icon" ]; then
                ICON_PATH="$icon"
                ICON_FOUND=true
            fi
        fi
        
        # Copy icon if found
        if [ "$ICON_FOUND" = true ]; then
            ICON_EXT="${ICON_PATH##*.}"
            cp "$ICON_PATH" "$PIXMAPS_DIR/${identifier}.${ICON_EXT}"
            ICON_FINAL="$PIXMAPS_DIR/${identifier}.${ICON_EXT}"
            echo "  → Icon extracted"
        else
            echo -e "  ${YELLOW}⚠ No icon found${NC}"
            ICON_FINAL=""
        fi
        
        # Try to find StartupWMClass from extracted desktop file
        STARTUP_WM_CLASS=""
        EXTRACTED_DESKTOP=$(find squashfs-root -name "*.desktop" -type f | head -1)
        if [ -n "$EXTRACTED_DESKTOP" ]; then
            STARTUP_WM_CLASS=$(grep "^StartupWMClass=" "$EXTRACTED_DESKTOP" 2>/dev/null | cut -d= -f2)
        fi
    else
        echo -e "  ${YELLOW}⚠ Could not extract AppImage (icon will be missing)${NC}"
        ICON_FINAL=""
        STARTUP_WM_CLASS=""
    fi
    
    # Clean up extraction
    cd ~ || true
    rm -rf "$TEMP_DIR"
    
    # Guess categories
    CATEGORIES=$(guess_categories "$app_name")
    
    # Create desktop entry
    echo "  → Creating desktop entry..."
    DESKTOP_FILE="$DESKTOP_DIR/${identifier}.desktop"
    
    cat > "$DESKTOP_FILE" << EOF
[Desktop Entry]
Name=$app_name
Comment=$app_name
Exec=$appimage_path %F
Icon=$ICON_FINAL
Terminal=false
Type=Application
Categories=$CATEGORIES;
EOF

    # Add StartupWMClass if found
    if [ -n "$STARTUP_WM_CLASS" ]; then
        echo "StartupWMClass=$STARTUP_WM_CLASS" >> "$DESKTOP_FILE"
        echo "  → Added StartupWMClass: $STARTUP_WM_CLASS"
    fi

    # Add MIME types for known apps
    case "$identifier" in
        *freecad*)
            echo "MimeType=application/x-extension-fcstd;" >> "$DESKTOP_FILE"
            ;;
        *orca*|*slicer*|*prusa*|*cura*)
            echo "MimeType=model/stl;application/x-3mf;application/vnd.ms-3mfdocument;" >> "$DESKTOP_FILE"
            ;;
        *blender*)
            echo "MimeType=application/x-blender;" >> "$DESKTOP_FILE"
            ;;
    esac
    
    chmod +x "$DESKTOP_FILE"
    
    echo -e "  ${GREEN}✓ Installed${NC}"
    echo ""
}

# Process each AppImage
INSTALLED_COUNT=0
SKIPPED_COUNT=0

for appimage in "${APPIMAGES[@]}"; do
    app_name=$(get_app_name "$appimage")
    identifier=$(get_identifier "$app_name")
    
    if [ "$FORCE_INSTALL" = false ] && desktop_entry_exists "$appimage" "$identifier"; then
        echo -e "${BLUE}⊙ $app_name${NC} - already installed, skipping"
        ((SKIPPED_COUNT++))
    else
        install_appimage "$appimage" "$app_name" "$identifier"
        ((INSTALLED_COUNT++))
    fi
done

# Update desktop database
if [ $INSTALLED_COUNT -gt 0 ]; then
    echo -e "${BLUE}Updating desktop database...${NC}"
    update-desktop-database "$DESKTOP_DIR"
    
    # Update icon cache if possible
    if command -v gtk-update-icon-cache &> /dev/null; then
        gtk-update-icon-cache -f "$HOME/.local/share/icons" 2>/dev/null || true
    fi
fi

# Summary
echo ""
echo -e "${BLUE}╔════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║  Summary                               ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════╝${NC}"
echo -e "${GREEN}✓ Installed:    $INSTALLED_COUNT${NC}"
echo -e "${BLUE}⊙ Skipped:     $SKIPPED_COUNT${NC}"
echo -e "${BLUE}═ Total:       ${#APPIMAGES[@]}${NC}"
echo ""

echo -e "${GREEN}Applications should now appear in your menu! ${NC}"
echo -e "${BLUE}You may need to wait a moment or reload your menu.${NC}"

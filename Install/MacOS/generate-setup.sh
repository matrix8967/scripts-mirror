#!/bin/bash
#
# macOS Setup Script Generator
# Generates deployment script from captured configuration
#
# Usage: ./generate-setup.sh -c <capture_dir> [-o output_file]
#
# Author: Azazel
# Purpose: Generate automated setup script for new Macs
#

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Default values
CAPTURE_DIR=""
OUTPUT_FILE="./generated-macos-setup.sh"

# Parse arguments
while getopts "c:o:h" opt; do
    case $opt in
        c) CAPTURE_DIR="$OPTARG" ;;
        o) OUTPUT_FILE="$OPTARG" ;;
        h)
            echo "Usage: $0 -c <capture_dir> [-o output_file]"
            echo "  -c: Capture directory (required)"
            echo "  -o: Output file (default: ./generated-macos-setup.sh)"
            exit 0
            ;;
        *)
            echo "Invalid option. Use -h for help."
            exit 1
            ;;
    esac
done

# Validate capture directory
if [ -z "$CAPTURE_DIR" ]; then
    echo -e "${RED}Error: Capture directory required (-c)${NC}"
    echo "Use -h for help"
    exit 1
fi

if [ ! -d "$CAPTURE_DIR" ]; then
    echo -e "${RED}Error: Capture directory not found: $CAPTURE_DIR${NC}"
    exit 1
fi

echo -e "${BLUE}[+] Generating macOS setup script from: $CAPTURE_DIR${NC}"
echo -e "${BLUE}[+] Output will be saved to: $OUTPUT_FILE${NC}"

# Start generating the setup script
cat > "$OUTPUT_FILE" << 'HEADER_EOF'
#!/bin/bash
#
# Automated macOS Setup Script
# Generated from captured configuration
#
# This script configures a fresh macOS install with your preferences
#
# Usage: ./generated-macos-setup.sh
#
# WARNING: Review this script before running!
# Some settings require logout/restart to take effect.
#

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${BLUE}╔════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║   macOS Automated Setup                    ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════╝${NC}"
echo ""

# Check if running on macOS
if [[ "$OSTYPE" != "darwin"* ]]; then
    echo -e "${RED}Error: This script is for macOS only${NC}"
    exit 1
fi

# Prompt for confirmation
echo -e "${YELLOW}This will modify system preferences and install applications.${NC}"
read -p "Continue? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Aborted."
    exit 0
fi

echo ""

HEADER_EOF

# ========================================
# HOMEBREW INSTALLATION
# ========================================
echo -e "${GREEN}[*] Adding Homebrew installation section...${NC}"

cat >> "$OUTPUT_FILE" << 'BREW_INSTALL_EOF'
# ========================================
# HOMEBREW INSTALLATION
# ========================================
echo -e "${GREEN}[1/8] Checking Homebrew...${NC}"

if ! command -v brew &> /dev/null; then
    echo "Homebrew not found. Installing..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

    # Add Homebrew to PATH for Apple Silicon
    if [[ $(uname -m) == 'arm64' ]]; then
        echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
        eval "$(/opt/homebrew/bin/brew shellenv)"
    fi
else
    echo "✓ Homebrew already installed"
fi

BREW_INSTALL_EOF

# ========================================
# HOMEBREW PACKAGES
# ========================================
if [ -f "$CAPTURE_DIR/02-Brewfile" ]; then
    echo -e "${GREEN}[*] Adding Homebrew package installation...${NC}"

    cat >> "$OUTPUT_FILE" << 'BREW_BUNDLE_EOF'
# ========================================
# HOMEBREW PACKAGES
# ========================================
echo -e "${GREEN}[2/8] Installing Homebrew packages...${NC}"

# Brewfile embedded below
cat > /tmp/Brewfile << 'BREWFILE_CONTENT'
BREW_BUNDLE_EOF

    # Embed the Brewfile
    cat "$CAPTURE_DIR/02-Brewfile" >> "$OUTPUT_FILE"

    cat >> "$OUTPUT_FILE" << 'BREW_BUNDLE_END'
BREWFILE_CONTENT

brew bundle --file=/tmp/Brewfile
rm /tmp/Brewfile

echo "✓ Homebrew packages installed"

BREW_BUNDLE_END
else
    cat >> "$OUTPUT_FILE" << 'NO_BREW_EOF'
# ========================================
# HOMEBREW PACKAGES
# ========================================
echo -e "${YELLOW}[2/8] Skipping Homebrew packages (no Brewfile found)${NC}"

NO_BREW_EOF
fi

# ========================================
# SYSTEM PREFERENCES - DOCK
# ========================================
echo -e "${GREEN}[*] Adding Dock preferences...${NC}"

cat >> "$OUTPUT_FILE" << 'DOCK_EOF'
# ========================================
# DOCK PREFERENCES
# ========================================
echo -e "${GREEN}[3/8] Configuring Dock...${NC}"

DOCK_EOF

# Parse dock settings from capture
if [ -f "$CAPTURE_DIR/04-defaults-dock.txt" ]; then
    # Extract key Dock settings
    while IFS= read -r line; do
        # Skip comments and empty lines
        [[ "$line" =~ ^[[:space:]]*# ]] && continue
        [[ -z "$line" ]] && continue

        # Common Dock settings to include
        if echo "$line" | grep -qE "(autohide|magnification|tilesize|orientation|mineffect|show-recents)"; then
            # Extract key and value
            if echo "$line" | grep -q "="; then
                key=$(echo "$line" | awk '{print $1}')
                value=$(echo "$line" | awk '{print $NF}' | tr -d ';')

                # Add to script
                echo "defaults write com.apple.dock $key -bool $value 2>/dev/null || defaults write com.apple.dock $key $value" >> "$OUTPUT_FILE"
            fi
        fi
    done < "$CAPTURE_DIR/04-defaults-dock.txt"
fi

cat >> "$OUTPUT_FILE" << 'DOCK_RESTART_EOF'

# Restart Dock to apply changes
killall Dock

echo "✓ Dock configured"

DOCK_RESTART_EOF

# ========================================
# SYSTEM PREFERENCES - FINDER
# ========================================
echo -e "${GREEN}[*] Adding Finder preferences...${NC}"

cat >> "$OUTPUT_FILE" << 'FINDER_EOF'
# ========================================
# FINDER PREFERENCES
# ========================================
echo -e "${GREEN}[4/8] Configuring Finder...${NC}"

# Show hidden files
defaults write com.apple.finder AppleShowAllFiles -bool true

# Show all file extensions
defaults write NSGlobalDomain AppleShowAllExtensions -bool true

# Show path bar
defaults write com.apple.finder ShowPathbar -bool true

# Show status bar
defaults write com.apple.finder ShowStatusBar -bool true

# Disable warning when changing file extensions
defaults write com.apple.finder FXEnableExtensionChangeWarning -bool false

# Restart Finder
killall Finder

echo "✓ Finder configured"

FINDER_EOF

# ========================================
# GLOBAL PREFERENCES
# ========================================
echo -e "${GREEN}[*] Adding global preferences...${NC}"

cat >> "$OUTPUT_FILE" << 'GLOBAL_EOF'
# ========================================
# GLOBAL PREFERENCES
# ========================================
echo -e "${GREEN}[5/8] Configuring global preferences...${NC}"

GLOBAL_EOF

# Check for dark mode
if [ -f "$CAPTURE_DIR/04-defaults-global.txt" ]; then
    if grep -q "AppleInterfaceStyle.*Dark" "$CAPTURE_DIR/04-defaults-global.txt"; then
        echo "# Enable Dark Mode" >> "$OUTPUT_FILE"
        echo "defaults write NSGlobalDomain AppleInterfaceStyle -string Dark" >> "$OUTPUT_FILE"
    fi
fi

cat >> "$OUTPUT_FILE" << 'GLOBAL_SETTINGS_EOF'

# Expand save panel by default
defaults write NSGlobalDomain NSNavPanelExpandedStateForSaveMode -bool true

# Expand print panel by default
defaults write NSGlobalDomain PMPrintingExpandedStateForPrint -bool true

# Disable auto-correct
defaults write NSGlobalDomain NSAutomaticSpellingCorrectionEnabled -bool false

echo "✓ Global preferences configured"

GLOBAL_SETTINGS_EOF

# ========================================
# SCREENSHOTS
# ========================================
echo -e "${GREEN}[*] Adding screenshot preferences...${NC}"

cat >> "$OUTPUT_FILE" << 'SCREENSHOT_EOF'
# ========================================
# SCREENSHOT PREFERENCES
# ========================================
echo -e "${GREEN}[6/8] Configuring screenshots...${NC}"

# Set screenshot location to ~/Pictures/Screenshots
mkdir -p "$HOME/Pictures/Screenshots"
defaults write com.apple.screencapture location -string "$HOME/Pictures/Screenshots"

# Set screenshot format to PNG
defaults write com.apple.screencapture type -string "png"

# Disable screenshot thumbnail
defaults write com.apple.screencapture show-thumbnail -bool false

# Restart SystemUIServer
killall SystemUIServer

echo "✓ Screenshot settings configured"

SCREENSHOT_EOF

# ========================================
# TRACKPAD
# ========================================
echo -e "${GREEN}[*] Adding trackpad preferences...${NC}"

cat >> "$OUTPUT_FILE" << 'TRACKPAD_EOF'
# ========================================
# TRACKPAD PREFERENCES
# ========================================
echo -e "${GREEN}[7/8] Configuring trackpad...${NC}"

# Enable tap to click
defaults write com.apple.AppleMultitouchTrackpad Clicking -bool true
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad Clicking -bool true
defaults -currentHost write NSGlobalDomain com.apple.mouse.tapBehavior -int 1

# Enable three-finger drag
defaults write com.apple.AppleMultitouchTrackpad TrackpadThreeFingerDrag -bool true
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad TrackpadThreeFingerDrag -bool true

echo "✓ Trackpad configured"

TRACKPAD_EOF

# ========================================
# SHELL CONFIGURATION
# ========================================
echo -e "${GREEN}[*] Adding shell configuration...${NC}"

cat >> "$OUTPUT_FILE" << 'SHELL_EOF'
# ========================================
# SHELL CONFIGURATION
# ========================================
echo -e "${GREEN}[8/8] Configuring shell...${NC}"

SHELL_EOF

if [ -f "$CAPTURE_DIR/07-default-shell.txt" ]; then
    CAPTURED_SHELL=$(cat "$CAPTURE_DIR/07-default-shell.txt")
    echo "# Set default shell to $CAPTURED_SHELL" >> "$OUTPUT_FILE"
    echo "if [ \"\$SHELL\" != \"$CAPTURED_SHELL\" ]; then" >> "$OUTPUT_FILE"
    echo "    chsh -s $CAPTURED_SHELL" >> "$OUTPUT_FILE"
    echo "    echo \"✓ Shell changed to $CAPTURED_SHELL (logout/login required)\"" >> "$OUTPUT_FILE"
    echo "else" >> "$OUTPUT_FILE"
    echo "    echo \"✓ Shell already set to $CAPTURED_SHELL\"" >> "$OUTPUT_FILE"
    echo "fi" >> "$OUTPUT_FILE"
fi

cat >> "$OUTPUT_FILE" << 'SHELL_END_EOF'

echo "✓ Shell configured"

SHELL_END_EOF

# ========================================
# FINAL NOTES
# ========================================
cat >> "$OUTPUT_FILE" << 'FOOTER_EOF'

echo ""
echo -e "${BLUE}╔════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║   Setup Complete!                          ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${YELLOW}Important:${NC}"
echo "  • Some settings require logout/restart to take effect"
echo "  • App Store apps need to be installed manually with 'mas'"
echo "  • Review login items in System Preferences"
echo "  • Sync dotfiles from scrolls/Configs/Shell/"
echo ""
echo -e "${GREEN}Recommended next steps:${NC}"
echo "  1. Logout and login again"
echo "  2. Install App Store apps: mas install <app_id>"
echo "  3. Configure remaining app-specific settings"
echo "  4. Restore Time Machine backup (if applicable)"
echo ""

FOOTER_EOF

# Make the generated script executable
chmod +x "$OUTPUT_FILE"

echo ""
echo -e "${GREEN}✓ Setup script generated successfully!${NC}"
echo -e "${YELLOW}  Saved to: $OUTPUT_FILE${NC}"
echo ""
echo -e "${GREEN}Next steps:${NC}"
echo "  1. Review the generated script"
echo "  2. Copy to new Mac"
echo "  3. Run: ./$OUTPUT_FILE"
echo ""
echo -e "${YELLOW}⚠️  WARNING: Review the script before running!${NC}"
echo "  Some settings are user-specific and may need adjustment."
echo ""

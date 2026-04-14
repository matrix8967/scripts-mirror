#!/bin/bash
#
# macOS Configuration Capture Script
# Captures system preferences, installed apps, and settings for automation
#
# Usage: ./capture-config.sh [-o output_dir]
#
# Author: Azazel
# Purpose: Document current macOS state for automated deployment
#

set -e

# Default output directory
OUTPUT_DIR="${HOME}/Documents/MacOSConfigs"
TIMESTAMP=$(date +"%Y-%m-%d_%H%M%S")

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Parse arguments
while getopts "o:h" opt; do
    case $opt in
        o) OUTPUT_DIR="$OPTARG" ;;
        h)
            echo "Usage: $0 [-o output_dir]"
            echo "  -o: Output directory (default: ~/Documents/MacOSConfigs)"
            exit 0
            ;;
        *)
            echo "Invalid option. Use -h for help."
            exit 1
            ;;
    esac
done

# Create capture directory
CAPTURE_DIR="${OUTPUT_DIR}/${TIMESTAMP}"
mkdir -p "$CAPTURE_DIR"

echo -e "${BLUE}[+] Capturing macOS configuration to: $CAPTURE_DIR${NC}"

# ========================================
# 1. SYSTEM INFORMATION
# ========================================
echo -e "${GREEN}[*] Capturing system information...${NC}"

sw_vers > "$CAPTURE_DIR/01-system-version.txt"
system_profiler SPSoftwareDataType SPHardwareDataType > "$CAPTURE_DIR/01-system-info.txt"
uname -a > "$CAPTURE_DIR/01-kernel-info.txt"

# ========================================
# 2. HOMEBREW PACKAGES
# ========================================
echo -e "${GREEN}[*] Capturing Homebrew packages...${NC}"

if command -v brew &> /dev/null; then
    # Brew bundle (best for restoration)
    brew bundle dump --file="$CAPTURE_DIR/02-Brewfile" --force

    # Detailed lists
    brew list --formula > "$CAPTURE_DIR/02-brew-formulae.txt" 2>/dev/null || echo "No formulae installed" > "$CAPTURE_DIR/02-brew-formulae.txt"
    brew list --cask > "$CAPTURE_DIR/02-brew-casks.txt" 2>/dev/null || echo "No casks installed" > "$CAPTURE_DIR/02-brew-casks.txt"

    # Taps
    brew tap > "$CAPTURE_DIR/02-brew-taps.txt"

    # Services
    brew services list > "$CAPTURE_DIR/02-brew-services.txt" 2>/dev/null || echo "No services" > "$CAPTURE_DIR/02-brew-services.txt"
else
    echo "Homebrew not installed" > "$CAPTURE_DIR/02-homebrew-not-found.txt"
fi

# ========================================
# 3. APP STORE APPLICATIONS
# ========================================
echo -e "${GREEN}[*] Capturing App Store applications...${NC}"

if command -v mas &> /dev/null; then
    mas list > "$CAPTURE_DIR/03-mas-apps.txt"
else
    echo "mas-cli not installed. Install with: brew install mas" > "$CAPTURE_DIR/03-mas-not-found.txt"
fi

# List all applications
ls -1 /Applications > "$CAPTURE_DIR/03-applications.txt"
ls -1 ~/Applications > "$CAPTURE_DIR/03-user-applications.txt" 2>/dev/null || touch "$CAPTURE_DIR/03-user-applications.txt"

# ========================================
# 4. SYSTEM PREFERENCES - GLOBAL
# ========================================
echo -e "${GREEN}[*] Capturing system preferences (defaults)...${NC}"

# NSGlobalDomain (most important system settings)
defaults read NSGlobalDomain > "$CAPTURE_DIR/04-defaults-global.txt" 2>/dev/null || echo "No global defaults" > "$CAPTURE_DIR/04-defaults-global.txt"

# Dock preferences
defaults read com.apple.dock > "$CAPTURE_DIR/04-defaults-dock.txt" 2>/dev/null || echo "No dock settings" > "$CAPTURE_DIR/04-defaults-dock.txt"

# Finder preferences
defaults read com.apple.finder > "$CAPTURE_DIR/04-defaults-finder.txt" 2>/dev/null || echo "No finder settings" > "$CAPTURE_DIR/04-defaults-finder.txt"

# Trackpad/Mouse
defaults read com.apple.AppleMultitouchTrackpad > "$CAPTURE_DIR/04-defaults-trackpad.txt" 2>/dev/null || echo "No trackpad settings" > "$CAPTURE_DIR/04-defaults-trackpad.txt"
defaults read com.apple.driver.AppleBluetoothMultitouch.trackpad > "$CAPTURE_DIR/04-defaults-trackpad-bt.txt" 2>/dev/null || echo "No BT trackpad settings" > "$CAPTURE_DIR/04-defaults-trackpad-bt.txt"

# Screenshots
defaults read com.apple.screencapture > "$CAPTURE_DIR/04-defaults-screencapture.txt" 2>/dev/null || echo "No screenshot settings" > "$CAPTURE_DIR/04-defaults-screencapture.txt"

# Safari
defaults read com.apple.Safari > "$CAPTURE_DIR/04-defaults-safari.txt" 2>/dev/null || echo "No Safari settings" > "$CAPTURE_DIR/04-defaults-safari.txt"

# Terminal
defaults read com.apple.Terminal > "$CAPTURE_DIR/04-defaults-terminal.txt" 2>/dev/null || echo "No Terminal settings" > "$CAPTURE_DIR/04-defaults-terminal.txt"

# Menu Bar
defaults read com.apple.menuextra > "$CAPTURE_DIR/04-defaults-menubar.txt" 2>/dev/null || echo "No menubar settings" > "$CAPTURE_DIR/04-defaults-menubar.txt"

# ========================================
# 5. LAUNCH AGENTS & DAEMONS
# ========================================
echo -e "${GREEN}[*] Capturing LaunchAgents and LaunchDaemons...${NC}"

# User LaunchAgents
ls -1 ~/Library/LaunchAgents/ > "$CAPTURE_DIR/05-launchagents-user.txt" 2>/dev/null || echo "No user LaunchAgents" > "$CAPTURE_DIR/05-launchagents-user.txt"

# System LaunchAgents
ls -1 /Library/LaunchAgents/ > "$CAPTURE_DIR/05-launchagents-system.txt" 2>/dev/null || echo "No system LaunchAgents" > "$CAPTURE_DIR/05-launchagents-system.txt"

# LaunchDaemons
ls -1 /Library/LaunchDaemons/ > "$CAPTURE_DIR/05-launchdaemons.txt" 2>/dev/null || echo "No LaunchDaemons" > "$CAPTURE_DIR/05-launchdaemons.txt"

# ========================================
# 6. LOGIN ITEMS
# ========================================
echo -e "${GREEN}[*] Capturing login items...${NC}"

osascript -e 'tell application "System Events" to get the name of every login item' > "$CAPTURE_DIR/06-login-items.txt" 2>/dev/null || echo "Unable to read login items" > "$CAPTURE_DIR/06-login-items.txt"

# ========================================
# 7. SHELL CONFIGURATION
# ========================================
echo -e "${GREEN}[*] Capturing shell configuration...${NC}"

echo "$SHELL" > "$CAPTURE_DIR/07-default-shell.txt"

# List installed shells
cat /etc/shells > "$CAPTURE_DIR/07-available-shells.txt"

# Current shell config files (if they exist)
for config in .zshrc .bashrc .bash_profile .profile .zprofile; do
    if [ -f "$HOME/$config" ]; then
        cp "$HOME/$config" "$CAPTURE_DIR/07-$config" 2>/dev/null || echo "Could not copy $config"
    fi
done

# ========================================
# 8. FONTS
# ========================================
echo -e "${GREEN}[*] Capturing installed fonts...${NC}"

ls -1 ~/Library/Fonts/ > "$CAPTURE_DIR/08-fonts-user.txt" 2>/dev/null || echo "No user fonts" > "$CAPTURE_DIR/08-fonts-user.txt"
ls -1 /Library/Fonts/ > "$CAPTURE_DIR/08-fonts-system.txt" 2>/dev/null || echo "No system fonts" > "$CAPTURE_DIR/08-fonts-system.txt"

# ========================================
# 9. NETWORK CONFIGURATION
# ========================================
echo -e "${GREEN}[*] Capturing network configuration...${NC}"

networksetup -listallnetworkservices > "$CAPTURE_DIR/09-network-services.txt" 2>/dev/null || echo "No network services" > "$CAPTURE_DIR/09-network-services.txt"
scutil --dns > "$CAPTURE_DIR/09-dns-config.txt" 2>/dev/null || echo "No DNS config" > "$CAPTURE_DIR/09-dns-config.txt"
ifconfig > "$CAPTURE_DIR/09-ifconfig.txt"

# ========================================
# 10. INSTALLED SDKS & DEVELOPMENT TOOLS
# ========================================
echo -e "${GREEN}[*] Capturing development tools...${NC}"

# Xcode
xcode-select -p > "$CAPTURE_DIR/10-xcode-path.txt" 2>/dev/null || echo "Xcode CLI tools not installed" > "$CAPTURE_DIR/10-xcode-path.txt"
xcodebuild -version > "$CAPTURE_DIR/10-xcode-version.txt" 2>/dev/null || echo "Xcode not installed" > "$CAPTURE_DIR/10-xcode-version.txt"

# Git
git --version > "$CAPTURE_DIR/10-git-version.txt" 2>/dev/null || echo "Git not installed" > "$CAPTURE_DIR/10-git-version.txt"

# Python
which python3 > "$CAPTURE_DIR/10-python-path.txt" 2>/dev/null && python3 --version >> "$CAPTURE_DIR/10-python-path.txt" 2>/dev/null || echo "Python3 not found" > "$CAPTURE_DIR/10-python-path.txt"

# Node
which node > "$CAPTURE_DIR/10-node-path.txt" 2>/dev/null && node --version >> "$CAPTURE_DIR/10-node-path.txt" 2>/dev/null || echo "Node not found" > "$CAPTURE_DIR/10-node-path.txt"

# Ruby
which ruby > "$CAPTURE_DIR/10-ruby-path.txt" 2>/dev/null && ruby --version >> "$CAPTURE_DIR/10-ruby-path.txt" 2>/dev/null || echo "Ruby not found" > "$CAPTURE_DIR/10-ruby-path.txt"

# ========================================
# 11. SYSTEM SETTINGS SUMMARY
# ========================================
echo -e "${GREEN}[*] Capturing key system settings...${NC}"

cat > "$CAPTURE_DIR/11-key-settings-summary.txt" << EOF
# macOS Key Settings Summary
# Generated: $(date)

## Dock Settings
Auto-hide: $(defaults read com.apple.dock autohide 2>/dev/null || echo "default")
Magnification: $(defaults read com.apple.dock magnification 2>/dev/null || echo "default")
Icon Size: $(defaults read com.apple.dock tilesize 2>/dev/null || echo "default")
Position: $(defaults read com.apple.dock orientation 2>/dev/null || echo "default")
Minimize Effect: $(defaults read com.apple.dock mineffect 2>/dev/null || echo "default")
Show Recent Apps: $(defaults read com.apple.dock show-recents 2>/dev/null || echo "default")

## Finder Settings
Show Hidden Files: $(defaults read com.apple.finder AppleShowAllFiles 2>/dev/null || echo "default")
Show All Extensions: $(defaults read NSGlobalDomain AppleShowAllExtensions 2>/dev/null || echo "default")
Show Path Bar: $(defaults read com.apple.finder ShowPathbar 2>/dev/null || echo "default")
Show Status Bar: $(defaults read com.apple.finder ShowStatusBar 2>/dev/null || echo "default")
Default View: $(defaults read com.apple.finder FXPreferredViewStyle 2>/dev/null || echo "default")

## Global Settings
Dark Mode: $(defaults read NSGlobalDomain AppleInterfaceStyle 2>/dev/null || echo "Light")
Accent Color: $(defaults read NSGlobalDomain AppleAccentColor 2>/dev/null || echo "default")
Sidebar Icon Size: $(defaults read NSGlobalDomain NSTableViewDefaultSizeMode 2>/dev/null || echo "default")
Scroll Bar: $(defaults read NSGlobalDomain AppleShowScrollBars 2>/dev/null || echo "default")

## Screenshot Settings
Location: $(defaults read com.apple.screencapture location 2>/dev/null || echo "default")
Format: $(defaults read com.apple.screencapture type 2>/dev/null || echo "default")
Show Thumbnail: $(defaults read com.apple.screencapture show-thumbnail 2>/dev/null || echo "default")

## Trackpad Settings
Tap to Click: $(defaults read com.apple.AppleMultitouchTrackpad Clicking 2>/dev/null || echo "default")
Tracking Speed: $(defaults read NSGlobalDomain com.apple.trackpad.scaling 2>/dev/null || echo "default")
Natural Scrolling: $(defaults read NSGlobalDomain com.apple.swipescrolldirection 2>/dev/null || echo "default")

EOF

# ========================================
# 12. GENERATE SUMMARY README
# ========================================
echo -e "${GREEN}[*] Generating summary...${NC}"

BREW_FORMULAE_COUNT=$(wc -l < "$CAPTURE_DIR/02-brew-formulae.txt" 2>/dev/null | tr -d ' ' || echo "0")
BREW_CASKS_COUNT=$(wc -l < "$CAPTURE_DIR/02-brew-casks.txt" 2>/dev/null | tr -d ' ' || echo "0")
APPS_COUNT=$(wc -l < "$CAPTURE_DIR/03-applications.txt" 2>/dev/null | tr -d ' ' || echo "0")
LAUNCHAGENTS_COUNT=$(wc -l < "$CAPTURE_DIR/05-launchagents-user.txt" 2>/dev/null | tr -d ' ' || echo "0")

cat > "$CAPTURE_DIR/00-README.txt" << EOF
# macOS Configuration Capture
Generated: $(date)
Hostname: $(hostname)
User: $(whoami)
macOS Version: $(sw_vers -productVersion)
Build: $(sw_vers -buildVersion)

## Quick Stats
- Homebrew Formulae: $BREW_FORMULAE_COUNT
- Homebrew Casks: $BREW_CASKS_COUNT
- Applications: $APPS_COUNT
- User LaunchAgents: $LAUNCHAGENTS_COUNT
- Shell: $SHELL

## Files Generated
EOF

# List all captured files with sizes
ls -lh "$CAPTURE_DIR" | tail -n +2 | awk '{printf "- %s (%s)\n", $9, $5}' >> "$CAPTURE_DIR/00-README.txt"

cat >> "$CAPTURE_DIR/00-README.txt" << EOF

## Next Steps
1. Review captured files
2. Run generate-setup.sh to create deployment script
3. Test in VM or secondary Mac
4. Keep captures local (not in git)

## Restore on New Mac
1. Clone scrolls repo
2. Copy Brewfile to new Mac
3. Run: brew bundle --file=Brewfile
4. Run generated setup script
5. Manually configure remaining settings

EOF

echo ""
echo -e "${BLUE}[+] Capture complete!${NC}"
echo -e "${YELLOW}    Saved to: $CAPTURE_DIR${NC}"
echo ""
echo -e "${GREEN}Files captured:${NC}"
ls -1 "$CAPTURE_DIR" | sed 's/^/    - /'
echo ""
echo -e "${GREEN}Next steps:${NC}"
echo "    1. Review: cat $CAPTURE_DIR/00-README.txt"
echo "    2. Generate automation: ./generate-setup.sh -c \"$CAPTURE_DIR\""
echo ""

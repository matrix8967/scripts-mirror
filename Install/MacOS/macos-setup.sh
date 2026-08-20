#!/bin/bash
#
# macOS Setup Script
# Hand-curated from captured configuration
#
# This script configures a fresh macOS install with your preferences
#
# Usage: ./macos-setup.sh
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

# The Brewfile below includes cargo packages, which require a Rust
# toolchain to already be on PATH - install it first so those entries
# don't fail on a brand-new machine.
if ! command -v cargo &> /dev/null; then
    echo "Rust/cargo not found. Installing via Homebrew..."
    brew install rust
else
    echo "✓ Rust/cargo already installed"
fi

# ========================================
# HOMEBREW PACKAGES
# ========================================
echo -e "${GREEN}[2/8] Installing Homebrew packages...${NC}"

# Brewfile embedded below
cat > /tmp/Brewfile << 'BREWFILE_CONTENT'
tap "blacktop/tap"
tap "clementtsang/bottom"
tap "homebrew/services"
tap "patopesto/tap"
tap "playcover/playcover"
tap "valkyrie00/bbrew"
tap "vladkens/tap"
brew "bat"
brew "bottom"
brew "bpytop"
brew "cpufetch"
brew "displayplacer"
brew "dnsmap"
brew "dnsperf"
brew "dnstop"
brew "dnstracer"
brew "dnsviz"
brew "fastfetch"
brew "git"
brew "glab"
brew "go"
brew "gtk+3"
brew "hidapi"
brew "inxi"
brew "ipcalc"
brew "iperf3"
brew "ipinfo-cli"
brew "ipv6calc"
brew "ipv6toolkit"
brew "jq"
brew "lsd"
brew "lsof"
brew "lsusb"
brew "mist-cli"
brew "mole"
brew "mpd"
brew "mpv"
brew "mtr"
brew "neofetch"
brew "nerdfetch"
brew "netfetch"
brew "nmap"
brew "onefetch"
brew "openssh"
brew "pfetch"
brew "pidof"
brew "pipx"
brew "pygobject3"
brew "screenfetch"
brew "sniffnet"
brew "speedtest-cli"
brew "tldr"
brew "tmux"
brew "trippy"
brew "watch"
brew "wget"
brew "wireguard-go"
brew "wireguard-tools"
brew "wireshark"
brew "blacktop/tap/ipsw"
brew "patopesto/tap/mdns-discovery"
brew "valkyrie00/bbrew/bbrew"
brew "vladkens/tap/macmon"
cask "1password-cli"
cask "betterdisplay"
cask "boop"
cask "core-tunnel"
cask "dnsmonitor"
cask "maccy"
cask "macdown"
cask "mist"
cask "monodraw"
cask "multipass"
cask "playcover/playcover/playcover-community"
cask "retroarch"
cask "stats"
cask "upscayl"
cask "vorta"
cask "warp"
cask "wireshark-chmodbpf"
cask "xquartz"
cargo "aarty"
cargo "apkeep"
cargo "bandwhich"
cargo "bat"
cargo "battop"
cargo "bottom"
cargo "cargo-bundle"
cargo "cargo-update"
cargo "cfonts"
cargo "checkpwn"
cargo "chess-tui"
cargo "csv-to-usv"
cargo "czkawka_cli"
cargo "daktilo"
cargo "dipc"
cargo "diskonaut"
cargo "doggo"
cargo "du-dust"
cargo "eureka"
cargo "fre"
cargo "gping"
cargo "hx"
cargo "imgcatr"
cargo "just"
cargo "kmon"
cargo "libreddit"
cargo "lsd"
cargo "mdbook"
cargo "names"
cargo "navi"
cargo "oha"
cargo "osintui"
cargo "oxker"
cargo "petname"
cargo "pfetch"
cargo "pixfetch"
cargo "presenterm"
cargo "procs"
cargo "qfetch"
cargo "rage"
cargo "rfetch"
cargo "ripgrep"
cargo "rustscan"
cargo "sniffnet"
cargo "spt"
cargo "systeroid"
cargo "systeroid-tui"
cargo "taskwarrior-tui"
cargo "toipe"
cargo "trip"
cargo "watchexec-cli"
cargo "xsv"
cargo "ytop"
cargo "zellij"
cargo "zenith"
BREWFILE_CONTENT

# Don't let one flaky tap/cask/cargo entry take down the rest of the
# script - brew bundle exits non-zero if ANY entry fails, and with
# set -e that would otherwise abort before Dock/Finder/etc ever run.
if brew bundle --file=/tmp/Brewfile; then
    echo "✓ Homebrew packages installed"
else
    echo -e "${YELLOW}⚠ Some Homebrew packages failed to install - review output above${NC}"
fi
rm /tmp/Brewfile

# ========================================
# DOCK PREFERENCES
# ========================================
echo -e "${GREEN}[3/8] Configuring Dock...${NC}"

defaults write com.apple.dock autohide -bool 1 2>/dev/null || defaults write com.apple.dock autohide 1
defaults write com.apple.dock "show-recents" -bool 0 2>/dev/null || defaults write com.apple.dock "show-recents" 0

# Restart Dock to apply changes
killall Dock

echo "✓ Dock configured"

# ========================================
# FINDER PREFERENCES
# ========================================
echo -e "${GREEN}[4/8] Configuring Finder...${NC}"

# Show hidden files
# defaults write com.apple.finder AppleShowAllFiles -bool true

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

# ========================================
# GLOBAL PREFERENCES
# ========================================
echo -e "${GREEN}[5/8] Configuring global preferences...${NC}"

# Enable Dark Mode
defaults write NSGlobalDomain AppleInterfaceStyle -string Dark

# Expand save panel by default
defaults write NSGlobalDomain NSNavPanelExpandedStateForSaveMode -bool true

# Expand print panel by default
defaults write NSGlobalDomain PMPrintingExpandedStateForPrint -bool true

# Disable auto-correct
defaults write NSGlobalDomain NSAutomaticSpellingCorrectionEnabled -bool false

echo "✓ Global preferences configured"

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

# ========================================
# SHELL CONFIGURATION
# ========================================
echo -e "${GREEN}[8/8] Configuring shell...${NC}"

# Set default shell to /bin/zsh
if [ "$SHELL" != "/bin/zsh" ]; then
    chsh -s /bin/zsh
    echo "✓ Shell changed to /bin/zsh (logout/login required)"
else
    echo "✓ Shell already set to /bin/zsh"
fi

echo "✓ Shell configured"


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

#!/bin/zsh

# warning warning wee woo wee woo

echo -e $RED"This is completely untested and there's no way it works until I put some TLC into it."$NC
read -s -n 1

# Install Brew

xcode-select --install

sudo xcodebuild -license

# Setup Homebrew:

/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Set Homebrew Environment Variables:

echo '# Set PATH, MANPATH, etc., for Homebrew.' >> /Users/$USERNAME/.zprofile
echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> /Users/$USERNAME/.zprofile
eval "$(opt/homebrew/bin/brew shellenv)"

# Disable Homebrew Analytics:

brew analytics off

# Install Homebrew Packages

brew install \
ansible \
aom \
asciinema \
autoconf \
bandwhich \
bash \
bat \
bdw-gc \
bmon \
boost \
bottom \
brotli \
c-ares \
ccat \
confuse \
curl \
ddgr \
docbook \
docbook-xsl \
fail2ban \
fftw \
figlet \
filezilla \
fontconfig \
freetype \
gcc \
gdbm \
gettext \
ghostscript \
giflib \
git \
glib \
glow \
gmp \
gnu-getopt \
gnupg \
gnutls \
go \
grepcidr \
guile \
htop \
httpie \
hwloc \
icu4c \
ifstat \
iftop \
ilmbase \
imagemagick \
imath \
imlib2 \
ipcalc \
isl \
jbig2dec \
jemalloc \
jpeg \
kitty \
libassuan \
libcaca \
libde265 \
libev \
libevent \
libffi \
libgcrypt \
libgpg-error \
libheif \
libidn \
libidn2 \
libksba \
liblqr \
libmetalink \
libmpc \
libmpdclient \
libomp \
libpcap \
libpng \
libpthread-stubs \
libssh2 \
libtasn1 \
libtiff \
libtool \
libunistring \
libusb \
libx11 \
libxau \
libxcb \
libxdmcp \
libxext \
libyaml \
libzip \
little-cms2 \
lolcat \
lsd \
m4 \
midnight-commander \
most \
mpc \
mpdecimal \
mpfr \
mplayer \
ncdu \
ncmpcpp \
ncurses \
neofetch \
nethogs \
nettle \
nghttp2 \
nmap \
npth \
open-mpi \
openexr \
openjpeg \
openldap \
openssl@1.1 \
p11-kit \
pcre \
pcre2 \
pinentry \
pkg-config \
pwgen \
python@3.9 \
qrencode \
readline \
rtmpdump \
rust \
s-lang \
screenresolution \
shared-mime-info \
speedtest-cli \
sqlite \
taglib \
tailscale \
tcpdump \
tldr \
tmux \
tree \
unbound \
utf8proc \
warp
webp \
wget \
wireguard-go \
wireguard-tools \
x265 \
xcodebuild \
xmlto \
xorgproto \
xz \
zstd

brew tap clementtsang/bottom
brew install bottom

brew install --cask xquartz
brew install xquartz \
quartz \
X11 \
xorg \
xcalc \
x11 \
xauth \
xquartz

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

# Install ohmyzsh

sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended

git clone https://github.com/romkatv/powerlevel10k.git ~/.oh-my-zsh/themes/powerlevel10k
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ~/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting
git clone https://github.com/zsh-users/zsh-autosuggestions ~/.oh-my-zsh/custom/plugins/zsh-autosuggestions
git clone https://github.com/redxtech/zsh-kitty ~/.oh-my-zsh/custom/plugins/zsh-kitty
git clone https://github.com/TamCore/autoupdate-oh-my-zsh-plugins ~/.oh-my-zsh/custom/plugins/autoupdate

cp ../Configs/Shell/MacOS_zsh_rc ~/.zshrc
cp ../Configs/Shell/p10k.zsh ~/.p10k.zsh

# Install Tmux
cp ../Configs/Shell/tmux.conf ~/.tmux.conf
git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm

# Install Vundle.
git clone https://github.com/VundleVim/Vundle.vim.git ~/.vim/bundle/Vundle.vim
cp ../Configs/Shell/vimrc ~/.vimrc
vim +PluginInstall +qall

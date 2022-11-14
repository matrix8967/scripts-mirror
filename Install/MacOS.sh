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
confuse \
curl \
ddgr \
docbook \
docbook-xsl \
fail2ban \
fftw \
figlet \
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
tcpdump \
tldr \
tmux \
tree \
unbound \
utf8proc \
webp \
wget \
wireguard-go \
wireguard-tools \
x265 \
xmlto \
xorgproto \
xz \
zstd \

brew tap clementtsang/bottom

brew install bottom

# Install ohmyzsh

sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended

git clone https://github.com/romkatv/powerlevel10k.git ~/.oh-my-zsh/themes/powerlevel10k
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ~/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting
git clone https://github.com/zsh-users/zsh-autosuggestions ~/.oh-my-zsh/custom/plugins/zsh-autosuggestions
git clone https://github.com/redxtech/zsh-kitty ~/.oh-my-zsh/custom/plugins/zsh-kitty

cp ../Configs/Shell/MacOS_zsh_rc ~/.zshrc
cp ../Configs/Shell/p10k.zsh ~/.p10k.zsh

# Install Tmux
cp ../Configs/Shell/tmux.conf ~/.tmux.conf
git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm

# Install Vundle.
git clone https://github.com/VundleVim/Vundle.vim.git ~/.vim/bundle/Vundle.vim
cp ../Configs/Shell/vimrc ~/.vimrc
vim +PluginInstall +qall

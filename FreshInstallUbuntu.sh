#!/bin/bash

RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color
VERS=$(gnome-shell  | cut -d " " -f 3)

# Prime the Sudo rights
sudo echo "Sudo Primed"

# Get updated...
echo -e ${GREEN}"Getting Updated..."${NC}
sudo apt update && sudo apt upgrade -y

# remove default snaps that should be apps instead...
echo -e "Removing default apps that are ${RED}snaps${NC}, that should have been ${GREEN}packages${NC}..."
sudo snap remove gnome-calculator gnome-logs gnome-system-monitor gnome-characters

# Install packages in the default repos...
echo -e ${GREEN}"Installing packages that are found in the default repos..."${NC}
sudo apt install -y git gnome-calculator gnome-logs gnome-system-monitor gnome-characters screenfetch neofetch unrar zsh gnome-tweak-tool chrome-gnome-shell steam htop iftop glances fonts-powerline wavemon vim vlc tilix tmux gparted fail2ban leafpad arc-theme curl steam-devices python-pip guake

# Install Signal...
echo -e "Installing ${GREEN}Signal...${NC}"
curl -s https://updates.signal.org/desktop/apt/keys.asc | sudo apt-key add -
echo "deb [arch=amd64] https://updates.signal.org/desktop/apt xenial main" | sudo tee -a /etc/apt/sources.list.d/signal-xenial.list
sudo apt update && sudo apt install -y signal-desktop

# Install Riot.im...
echo -e "Installing ${GREEN}Riot.im...${NC}"
sudo sh -c "echo 'deb https://riot.im/packages/debian/ bionic main' > /etc/apt/sources.list.d/matrix-riot-im.list"
curl -L https://riot.im/packages/debian/repo-key.asc | sudo apt-key add -
sudo apt update && sudo apt -y install riot-web

# Create folders in ~/
mkdir ~/Downloads/Appimages
mkdir ~/Downloads/Debs

# Install Bitwarden...
echo -e "Downloading Bitwarden to ${GREEN}~/Downloads/AppImages/${NC}"
curl -L https://vault.bitwarden.com/download/\?app\=desktop\&platform\=linux --output "~/Downloads/Appimages/BitWarden.AppImage"

# Install Sweet-Dark
echo -e "Downloading and Installing Sweet-Dark Theme..."
sudo mkdir -p /usr/share/themes/Sweet-Dark/
git clone https://github.com/EliverLara/Sweet.git /usr/share/themes/Sweet-Dark/
gsettings set org.gnome.desktop.interface gtk-theme "Sweet-Dark"
gsettings set org.gnome.desktop.wm.preferences theme "Sweet-Dark"

# Install OhMyZsh, and PowerLevel9K Theme...
echo -e "Installing ${GREEN}OhMyZsh${NC} and ${GREEN}PowerLevel9K${NC} Theme..."
sh -c "$(curl -fsSL https://raw.github.com/robbyrussell/oh-my-zsh/master/tools/install.sh)"
git clone https://github.com/bhilburn/powerlevel9k.git ~/.oh-my-zsh/custom/themes/powerlevel9k
sed -i -e 's/^ZSH_THEME="robbyrussell"/ZSH_THEME="powerlevel9k\/powerlevel9k"/' ~/.zshrc

# Setup NanoRC
cat <<EOF > ~/.nanorc
set constantshow
set linenumbers
set nonewlines
set softwrap
EOF

# Setup Sublime Text...

wget -qO - https://download.sublimetext.com/sublimehq-pub.gpg | sudo apt-key add -
sudo apt install -y apt-transport-https
echo "deb https://download.sublimetext.com/ apt/stable/" | sudo tee /etc/apt/sources.list.d/sublime-text.list
sudo apt update
sudo apt install sublime-text

# Install Gnome Shell Extensions...(Thanks https://github.com/NicolasBernaerts/)

echo -e "Attempting to install Gnome Extensions."

sudo wget -O /usr/local/bin/gnomeshell-extension-manage "https://raw.githubusercontent.com/NicolasBernaerts/ubuntu-scripts/master/ubuntugnome/gnomeshell-extension-manage"

sudo chmod +x /usr/local/bin/gnomeshell-extension-manage

gnomeshell-extension-manage --install --extension-id 1228 --user

gnomeshell-extension-manage --install --extension-id 307 --user

gnomeshell-extension-manage --install --extension-id 800 --user

gnomeshell-extension-manage --install --extension-id 19 --user

gnomeshell-extension-manage --install --extension-id 841 --user

gnomeshell-extension-manage --install --extension-id 826 --user

gnome-shell --replace &

# Install Nvidia Drivers...
echo -e "Installing Nvidia Drivers..."
sudo add-apt-repository ppa:graphics-drivers
sudo apt update
sudo apt install -y nvidia-driver-415

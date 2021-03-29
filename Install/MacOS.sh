#!/bin/zsh

# warning warning wee woo wee woo

echo -e $RED"This is completely untested and there's no way it works until I put some TLC into it."$NC
read -s -n 1

# Install Brew

xcode-select --install

/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Install Brew Packages

brew install neofetch git tmux wget lsd ytop tldr ddgr imagemagick most mplayer mc ncdu lolcat figlet mpc ncmpcpp tree pwgen ipcalc nmap curl golang httpie tcpdump ncdu asciinema tree speedtest-cli fail2ban ipcalc pwgen htop iftop cargo rust glow bat wireguard-tools

brew tap clementtsang/bottom

brew install bottom

# Install ohmyzsh

sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
git clone https://github.com/romkatv/powerlevel10k.git ~/.oh-my-zsh/themes/powerlevel10k
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ~/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting
git clone https://github.com/zsh-users/zsh-autosuggestions ~/.oh-my-zsh/custom/plugins/zsh-autosuggestions

# Copy dotfiles for MacOS:

cp ../Configs/Shell/zshrc ~/.zshrc

cp ../Configs/Shell/tmux.conf ~/.tmux.conf
git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
git clone https://github.com/VundleVim/Vundle.vim.git ~/.vim/bundle/Vundle.vim
cp ../Configs/Shell/vimrc ~/.vimrc
vim +PluginInstall +qall

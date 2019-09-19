#!/bin/bash

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

# Install Zsh, OhMyZsh, PowerLevel9K Theme, and NerdFonts...
echo -e "Installing ${GREEN}NerdFonts, OhMyZsh${NC} and ${GREEN}PowerLevel9K${NC} Theme..."
mkdir /home/$USER/.fonts
wget https://github.com/ryanoasis/nerd-fonts/releases/download/v2.0.0/AnonymousPro.zip -P /home/$USER/.fonts/
wget https://github.com/ryanoasis/nerd-fonts/releases/download/v2.0.0/Hack.zip -P /home/$USER/.fonts/
wget https://github.com/ryanoasis/nerd-fonts/releases/download/v2.0.0/RobotoMono.zip -P /home/$USER/.fonts/
wget https://github.com/ryanoasis/nerd-fonts/releases/download/v2.0.0/Terminus.zip -P /home/$USER/.fonts/
wget https://github.com/ryanoasis/nerd-fonts/releases/download/v2.0.0/Ubuntu.zip -P /home/$USER/.fonts/
wget https://github.com/ryanoasis/nerd-fonts/releases/download/v2.0.0/UbuntuMono.zip -P /home/$USER/.fonts/
unzip ~/.fonts/'*.zip' -d /home/$USER/.fonts/
fc-cache
sh -c "$(curl -fsSL https://raw.github.com/robbyrussell/oh-my-zsh/master/tools/install.sh)" -P /home/$USER/.fonts/
git clone https://github.com/bhilburn/powerlevel9k.git ~/.oh-my-zsh/custom/themes/powerlevel9k
sed -i -e 's/^ZSH_THEME="robbyrussell"/ZSH_THEME="powerlevel9k\/powerlevel9k"/' ~/.zshrc
sed -i '1 i\POWERLEVEL9K_MODE='nerdfont-complete'\n' ~/.zshrc
cat <<EOF >> ~/.zshrc
screenfetch

## User with skull
# user_with_skull() {
#     echo -n "\ufb8a $(whoami)"
# }
# POWERLEVEL9K_CUSTOM_USER="user_with_skull"
# POWERLEVEL9K_CUSTOM_USER_FOREGROUND="black"
# POWERLEVEL9K_CUSTOM_USER_BACKGROUND="red"

POWERLEVEL9K_CONTEXT_DEFAULT_BACKGROUND='green'
POWERLEVEL9K_CONTEXT_DEFAULT_FOREGROUND='black'

POWERLEVEL9K_TIME_FORMAT="%D{\uf073 %m.%d.%y %H:%M}"
POWERLEVEL9K_TIME_FOREGROUND='black'
POWERLEVEL9K_TIME_BACKGROUND='green'

# Battery (laptop.)
POWERLEVEL9K_BATTERY_VERBOSE=true
POWERLEVEL9K_BATTERY_CHARGING='yellow'
POWERLEVEL9K_BATTERY_CHARGED='green'
POWERLEVEL9K_BATTERY_DISCONNECTED='$DEFAULT_COLOR' #This was acting weird...?
POWERLEVEL9K_BATTERY_LOW_THRESHOLD='10'
POWERLEVEL9K_BATTERY_LOW_COLOR='red'
POWERLEVEL9K_BATTERY_ICON='\uf1e6 '
POWERLEVEL9K_BATTERY_LOW_FOREGROUND='red'
POWERLEVEL9K_BATTERY_CHARGING_FOREGROUND='blue'
POWERLEVEL9K_BATTERY_CHARGED_FOREGROUND='green'
POWERLEVEL9K_BATTERY_DISCONNECTED_FOREGROUND='blue'

# Left and Right Prompt/Line handling.

POWERLEVEL9K_PROMPT_ON_NEWLINE=true
POWERLEVEL9K_RPROMPT_ON_NEWLINE=false
# POWERLEVEL9K_MULTILINE_FIRST_PROMPT_PREFIX="%{%F{249}%}\u250f"
# POWERLEVEL9K_MULTILINE_LAST_PROMPT_PREFIX="%{%F{249}%}\u2517%{%F{default}%}❯"
# POWERLEVEL9K_MULTILINE_LAST_PROMPT_PREFIX=''
POWERLEVEL9K_MULTILINE_FIRST_PROMPT_PREFIX=''
POWERLEVEL9K_MULTILINE_LAST_PROMPT_PREFIX='\ufb0c '

# POWERLEVEL9K_LEFT_PROMPT_ELEMENTS=(context dir vcs battery vpn_ip public_ip ip icons_test)
POWERLEVEL9K_RIGHT_PROMPT_ELEMENTS=(status root_indicator background_jobs history time battery)
POWERLEVEL9K_LEFT_PROMPT_ELEMENTS=(os_icon context dir vcs)
POWERLEVEL9K_SHORTEN_DIR_LENGTH=2
POWERLEVEL9K_PROMPT_ADD_NEWLINE=true

# =====Misc. Env Variables=====

export GOPATH=$HOME/Git/Misc/Go/
EOF

# Setup NanoRC
cat <<EOF > ~/.nanorc
set constantshow
set linenumbers
set nonewlines
set softwrap
EOF

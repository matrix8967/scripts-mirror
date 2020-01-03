# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block, everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

export TERM="xterm-256color"

POWERLEVEL9K_MODE='nerdfont-complete'

# Path to your oh-my-zsh installation.
export ZSH="/home/$USER/.oh-my-zsh"

ZSH_THEME=powerlevel10k/powerlevel10k

plugins=(git zsh-syntax-highlighting)

source $ZSH/oh-my-zsh.sh


# =====MOTD===== #

echo -e
echo -e
/usr/bin/env figlet -w 100 -c -k -f Slant\ Relief "$(hostname)" | lolcat
echo -e
echo -e

# =====Python===== #

export PATH=$PATH:~/.local/bin/

# =====GoLang===== #

export GOPATH=/home/$USER/Git/Misc/Go/
export PATH=$PATH:/usr/local/go/bin

# =====Ruby=====

export GEM_HOME="$HOME/.gems"
export PATH="$HOME/.gems/bin:$PATH"

# =====Kitty Config===== #

autoload -Uz compinit
compinit
# Completion for kitty
kitty + complete setup zsh | source /dev/stdin

# =====Aliases===== #

alias nano='vim'
alias pls='sudo'
alias ls='lsd'
alias l='ls -l'
alias la='ls -a'
alias lla='ls -la'
alias lt='ls --tree'

# =====Functions===== #

function weather {
  curl -s "http://wttr.in/Little Rock" | head -n 27
}

function amimullvad {
	curl https://am.i.mullvad.net/connected
}

function dig_outside {
dig +short myip.opendns.com @resolver1.opendns.com
}

function MXErgo {
~/Scripts/./MXErgo.sh
}

function ElecomDeftPro {
~/Scripts/./ElecomDeftPro.sh
}

function ElecomEX-GPro {
~/Scripts/./ElecomEX-GPro.sh
}

# =====Blur for Kitty Term===== #

if [[ $(ps --no-header -p $PPID -o comm) =~ '^yakuake|kitty$' ]]; then
        for wid in $(xdotool search --pid $PPID); do
            xprop -f _KDE_NET_WM_BLUR_BEHIND_REGION 32c -set _KDE_NET_WM_BLUR_BEHIND_REGION 0 -id $wid; done
fi

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

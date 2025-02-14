#!/usr/bin/env bash

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

export GO111MODULES=auto

go install github.com/charmbracelet/glow@latest
go install github.com/maaslalani/draw@latest
# go get -u github.com/jingweno/ccat
go install github.com/jesseduffield/lazydocker@latest
go install github.com/sachaos/tcpterm@latest
# go get -u github.com/vultr/govultr/v2
go install github.com/gonetx/httpit@latest
go install github.com/jesseduffield/lazygit@latest
go install github.com/jmhobbs/terminal-parrot@latest
# go get github.com/cointop-sh/cointop
go install github.com/cointop-sh/cointop@latest
go install github.com/charmbracelet/gum@latest
go install github.com/maaslalani/gambit@latest
go install github.com/maaslalani/cue@latest
go install github.com/c-grimshaw/gosniff@latest
go install github.com/maaslalani/slides@latest
go install github.com/fabio42/ssl-checker@latest
go install github.com/mr-karan/doggo/cmd/doggo@latest
go install github.com/TheZoraiz/ascii-image-converter@latest
go install github.com/AkashRajpurohit/git-sync@latest
go install github.com/aayushbtw/monit@latest
go install github.com/Zebbeni/ansizalizer@latest
go install github.com/BigJk/imeji/cmd/imeji@latest
go install github.com/jordanella/go-ansi-paintbrush@latest
go install github.com/bradfitz/embiggen-disk@latest
go install github.com/DerTimonius/twkb@latest
go install github.com/ddddddO/packemon/cmd/packemon@latest
go install github.com/abhimanyu003/sttr@latest
go install github.com/szktkfm/mdtt/cmd/mdtt@latest
go install github.com/darkhz/bluetuith@latest
go install github.com/Zxilly/go-size-analyzer/cmd/gsa@latest
go install github.com/mrusme/planor@latest
go install github.com/Lifailon/lazyjournal@latest
go install github.com/ycd/dstp/cmd/dstp@latest
go install github.com/codeshaine/curlify@latest

# rm -rf /usr/local/go && tar -C /usr/local -xzf go1.21.4.linux-amd64.tar.gz

sudo cp $GOPATH/bin/* /usr/bin/

# git -C /home/$USER/Git/Misc/ clone https://github.com/charmbracelet/glow.git

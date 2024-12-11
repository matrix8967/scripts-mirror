#!/usr/bin/env bash

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh

# cargo install apkeep bandwhich bat battop bottom cargo-bundle cargo-update checkpwn cloak czkawka_cli du-dust gitui gpg-tui gping hx libreddit lsd ludusavi mdbook names navi onefetch petname pfetch pixfetch procs qfetch rage rfetch ripgrep rustdesk rustscan sniffnet taskwarrior-tui toipe watchexec-cli ytop

cargo install aarty \
amdgpu_top \
apkeep \
bandwhich \
bat \
battop \
bluetui \
bottom \
cargo-bundle \
cargo-update \
cfonts \
checkpwn \
chess-tui \
cloak \
csv-to-usv \
czkawka_cli \
daktilo \
dipc \
diskonaut \
doggo \
du-dust \
eureka \
fre \
gitui \
gpg-tui \
gping \
hurl \
hx \
imgcatr \
impala \
just \
kdash \
kmon \
libreddit \
logss \
lsd \
ludusavi \
mdbook \
names \
navi \
netop \
oha \
onefetch \
osintui \
oxker \
petname \
pfetch \
pixfetch \
presenterm \
procs \
projectable \
qfetch \
qsv \
rage \
rerun-cli \
rfetch \
rioterm \
ripgrep \
rustdesk \
rustic-rs \
rustscan \
scryptenc-cli \
sniffnet \
spotifyd \
spotify-tui \
systeroid \
systeroid-tui \
tailspin \
taskwarrior-tui \
toipe \
tracexec \
trippy \
uefisettings \
watchexec-cli \
xsv \
yazi-cli \
yazi-fm \
ytop \
zellij \
zenith

sudo setcap cap_sys_ptrace,cap_dac_read_search,cap_net_raw,cap_net_admin+ep $(which bandwhich)

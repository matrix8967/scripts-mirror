#!/usr/bin/env bash

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh

# cargo install apkeep bandwhich bat battop bottom cargo-bundle cargo-update checkpwn cloak czkawka_cli du-dust gitui gpg-tui gping hx libreddit lsd ludusavi mdbook names navi onefetch petname pfetch pixfetch procs qfetch rage rfetch ripgrep rustdesk rustscan sniffnet taskwarrior-tui toipe watchexec-cli ytop

cargo install aarty  \
agg \
airshipper \
amdgpu_top \
apkeep \
bandwhich \
basilk \
bat \
battop \
binsider \
bluetui \
bmm \
bottom \
bpf-linker \
brush-shell \
cargo-binstall \
cargo-bundle \
cargo-update \
cfonts \
checkpwn \
chess-tui \
cloak \
comchan \
csv-to-usv \
czkawka_cli \
daktilo \
darya \
dipc \
diskonaut \
dns-bench \
doggo \
dotstate \
doxx \
du-dust \
eureka \
fclones \
fre \
gitui \
glim-tui \
glues \
gmap \
gpg-tui \
gping \
humble-cli \
hurl \
hx \
imgcatr \
impala \
inspect-cert-chain \
ironfoil \
judo \
just \
kanha \
kdash \
kmon \
lapce \
libreddit \
logss \
lsd \
ludusavi \
managarr \
mcp-cli \
mdbook \
mdns-scanner \
names \
navi \
netop \
netscanner \
nexus-tui \
nu \
nvrs \
oha \
onefetch \
oryx \
osintui \
otree \
ox \
oxker \
parqeye \
pastel \
pcap-minimizer \
petname \
pfetch \
pixfetch \
presenterm \
procs \
projectable \
purple-ssh \
qfetch \
qmassa \
qsv \
rage \
rascii_art \
rerun-cli \
rfetch \
rioterm \
ripgrep \
rucola-notes \
rustic-rs \
rustnet-monitor \
rustscan \
scryptenc-cli \
serie \
spotifyd \
spotify-tui \
sprofile \
sshs \
swaptop \
systemctl-tui \
systeroid \
systeroid-tui \
tailspin \
taskwarrior-tui \
termframe \
tlrc \
toipe \
topgrade \
tracexec \
tracker \
t-rec \
trippy \
tui-journal \
uefisettings \
watchexec-cli \
xsv \
yazi-cli \
yazi-fm \
ytop \
zellij \
zenith

sudo setcap cap_sys_ptrace,cap_dac_read_search,cap_net_raw,cap_net_admin+ep $(which bandwhich)

#!/usr/bin/env bash
# backup-system.sh — distro-agnostic, encrypted, compressed system backup.
#
# Captures package inventories, desktop/session metadata, system snapshot,
# and rsync-staged tarballs of /etc, $HOME, and selected custom paths.
# Each archive is streamed through zstd and encrypted with GPG.
#
# Default mode is --dry-run; pass --execute to actually write to disk.
# Run `./backup-system.sh --help` for full usage.

set -Eeuo pipefail

VERSION="0.1.0"
SCRIPT="$(basename "$0")"
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"

# shellcheck source=backup-lib.sh
source "$SCRIPT_DIR/backup-lib.sh"

# Surface every errexit failure with line + command + status so the script
# can never just disappear silently (the original TUI symptom).
on_err() {
    local rc=$?
    log_error "errexit at ${BASH_SOURCE[1]:-?}:${BASH_LINENO[0]:-?} — \"${BASH_COMMAND}\" (rc=$rc)"
    exit "$rc"
}
trap on_err ERR

# ---------------------------------------------------------------
# defaults  (every flag below is overridable on the command line)
# ---------------------------------------------------------------
DRY_RUN=1
DEST=""
USE_TUI="auto"
GPG_RECIPIENT=""
GPG_SYMMETRIC=0
ENCRYPT_ALL=0
IMMUTABLE=0
KEEP_STAGING=0
LINK_DEST=""
ZSTD_LEVEL=19
SMB_CREDENTIALS=""
VERBOSE=0
DEBUG=0

# Sections in default order. Each one may be skipped via --skip.
declare -a ALL_SECTIONS=(packages desktop system etc home custom)
declare -a SECTIONS=("${ALL_SECTIONS[@]}")
declare -a CUSTOM_PATHS=(/usr/local/etc /opt /var/spool/cron /root)

usage() {
    cat <<EOF
$SCRIPT v$VERSION — encrypted, compressed system backup

USAGE
    $SCRIPT --dest <PATH|smb://...|nfs://...|file://...> [options]

REQUIRED
    --dest PATH         Where to write the backup. Accepts:
                          /local/path
                          file:///local/path
                          smb://[user@]host/share[/subpath]
                          cifs://[user@]host/share[/subpath]
                          nfs://host/exported/path
                        Remote schemes mount to a temp dir for the run.

SAFETY (default: dry-run is ON)
    --dry-run           Preview only. No files written. (DEFAULT)
    --execute           Disable dry-run; actually perform the backup.

ENCRYPTION
    --gpg-recipient ID  GPG key ID, fingerprint, or email for asymmetric
                        encryption. Use this for unattended runs.
    --gpg-symmetric     Use passphrase-based symmetric encryption (AES256).
                        gpg-agent will prompt once per archive unless cached.
    --encrypt-all       Encrypt the package/system inventories too.
                        (Default: leave them as plain text so you can read
                        them on a fresh install before decrypting anything.)

CONTENT
    --include LIST      Comma-separated sections to include.
                        Available: ${ALL_SECTIONS[*]}
                        Default: all
    --skip LIST         Comma-separated sections to skip.
    --custom-path PATH  Add an extra absolute path to the 'custom' archive.
                        Repeatable.

REMOTE / TRANSPORT
    --smb-credentials FILE
                        Path to a CIFS credentials file (username=,
                        password=, domain=). Otherwise rely on user@ in URL
                        or kerberos.

ARCHIVE TUNING
    --zstd-level N      Compression level 1-22. Default: $ZSTD_LEVEL.
    --link-dest DIR     Path to a previous backup session's directory.
                        rsync will hardlink unchanged files (cheap snapshot
                        chain — manual incremental until borg lands).
    --keep-staging      Don't delete the rsync staging tree after archive
                        creation. Useful for browsing without decryption.
    --immutable         After writing, set output to chattr +i (ext4/xfs/
                        btrfs only; requires root). Off by default.

INTERFACE
    --tui               Force interactive whiptail walkthrough.
    --no-tui            Force non-interactive (flags only).
    -v, --verbose       Echo every shell command before running it.
    --debug             set -x style trace + diagnostic output. Use this
                        when the TUI seems to exit without explanation.

OTHER
    -h, --help          This message.
    --version           Print version and exit.

EXAMPLES

  Preview a backup to a local SSD (no writes happen):
      $SCRIPT --dest /mnt/backup --gpg-recipient alex.m@controld.com

  Run for real to a CIFS share, key-based encryption:
      $SCRIPT --dest smb://nas.local/backups/witchhammer \\
              --smb-credentials ~/.smbcreds \\
              --gpg-recipient 0xDEADBEEFCAFEBABE \\
              --execute

  Symmetric (passphrase) backup, all sections, into NFS:
      $SCRIPT --dest nfs://nas.local/volume1/backups \\
              --gpg-symmetric --execute

  Hardlink-based snapshot relative to last good run:
      $SCRIPT --dest /mnt/backup \\
              --link-dest /mnt/backup/witchhammer-2026-05-01T120000Z \\
              --gpg-recipient alex.m@controld.com --execute
EOF
}

version() { printf '%s %s\n' "$SCRIPT" "$VERSION"; }

# ---------------------------------------------------------------
# argv parsing
# ---------------------------------------------------------------
parse_args() {
    while (( $# )); do
        case "$1" in
            --dest)            DEST="$2"; shift 2 ;;
            --dest=*)          DEST="${1#*=}"; shift ;;
            --dry-run)         DRY_RUN=1; shift ;;
            --execute)         DRY_RUN=0; shift ;;
            --gpg-recipient)   GPG_RECIPIENT="$2"; shift 2 ;;
            --gpg-recipient=*) GPG_RECIPIENT="${1#*=}"; shift ;;
            --gpg-symmetric)   GPG_SYMMETRIC=1; shift ;;
            --encrypt-all)     ENCRYPT_ALL=1; shift ;;
            --include)         IFS=',' read -ra SECTIONS <<<"$2"; shift 2 ;;
            --include=*)       IFS=',' read -ra SECTIONS <<<"${1#*=}"; shift ;;
            --skip)            _apply_skip "$2"; shift 2 ;;
            --skip=*)          _apply_skip "${1#*=}"; shift ;;
            --custom-path)     CUSTOM_PATHS+=("$2"); shift 2 ;;
            --custom-path=*)   CUSTOM_PATHS+=("${1#*=}"); shift ;;
            --smb-credentials) SMB_CREDENTIALS="$2"; shift 2 ;;
            --smb-credentials=*) SMB_CREDENTIALS="${1#*=}"; shift ;;
            --zstd-level)      ZSTD_LEVEL="$2"; shift 2 ;;
            --zstd-level=*)    ZSTD_LEVEL="${1#*=}"; shift ;;
            --link-dest)       LINK_DEST="$2"; shift 2 ;;
            --link-dest=*)     LINK_DEST="${1#*=}"; shift ;;
            --keep-staging)    KEEP_STAGING=1; shift ;;
            --immutable)       IMMUTABLE=1; shift ;;
            --tui)             USE_TUI=yes; shift ;;
            --no-tui)          USE_TUI=no; shift ;;
            -v|--verbose)      VERBOSE=1; shift ;;
            --debug)           DEBUG=1; VERBOSE=1; shift ;;
            -h|--help)         usage; exit 0 ;;
            --version)         version; exit 0 ;;
            *)                 die "unknown argument: $1  (try --help)" ;;
        esac
    done
}

_apply_skip() {
    local skip_csv="$1"
    local -A skipset=()
    local s
    local -a skips
    IFS=',' read -ra skips <<<"$skip_csv"
    for s in "${skips[@]}"; do skipset[$s]=1; done
    local -a kept=()
    for s in "${SECTIONS[@]}"; do
        [[ -n "${skipset[$s]:-}" ]] || kept+=("$s")
    done
    SECTIONS=("${kept[@]}")
}

# ---------------------------------------------------------------
# tooling probe
# ---------------------------------------------------------------
detect_tools() {
    require_cmd rsync rsync
    require_cmd tar   tar
    require_cmd zstd  zstd
    require_cmd gpg   "gnupg or gnupg2"
    require_cmd sha256sum coreutils
    have_cmd jq      || log_warn "jq not found — manifest will be written without pretty-printing"
}

# ---------------------------------------------------------------
# GPG environment + passphrase setup
# ---------------------------------------------------------------
PASSPHRASE_FILE=""

shred_passphrase_file() {
    if [[ -n "$PASSPHRASE_FILE" && -f "$PASSPHRASE_FILE" ]]; then
        if have_cmd shred; then
            shred -u "$PASSPHRASE_FILE" 2>/dev/null || rm -f "$PASSPHRASE_FILE"
        else
            rm -f "$PASSPHRASE_FILE"
        fi
    fi
}
add_cleanup_hook shred_passphrase_file

# Always have GPG_TTY exported so any pinentry call (e.g. for asymmetric
# signing) can find a real terminal even when invoked via sudo / pipes.
configure_gpg_env() {
    if [[ -z "${GPG_TTY:-}" && -t 0 ]]; then
        local t
        t="$(tty 2>/dev/null || true)"
        [[ "$t" == /dev/* ]] && export GPG_TTY="$t"
    fi
    # When run via sudo, point gpg at the original user's keyring; otherwise
    # asymmetric mode would look in /root/.gnupg and fail to find the key.
    if [[ -n "${SUDO_USER:-}" && -z "${GNUPGHOME:-}" && $EUID -eq 0 ]]; then
        local user_home user_gnupg
        user_home="$(getent passwd "$SUDO_USER" | cut -d: -f6)"
        user_gnupg="${user_home}/.gnupg"
        if [[ -d "$user_gnupg" ]]; then
            export GNUPGHOME="$user_gnupg"
            log_info "running under sudo: GNUPGHOME=$GNUPGHOME (using $SUDO_USER's keyring)"
        fi
    fi
}

# Read the symmetric passphrase ONCE and stash it in a 0600 temp file. gpg
# then reads it via --pinentry-mode loopback --passphrase-file, so no TTY
# pinentry call is needed and the same passphrase works for every archive.
setup_passphrase() {
    (( GPG_SYMMETRIC )) || return 0
    dry && { log_dry "would prompt for symmetric passphrase"; return 0; }

    PASSPHRASE_FILE="$(mktemp -t scrolls-pp.XXXXXX)"
    chmod 0600 "$PASSPHRASE_FILE"

    local p1 p2 rc=0
    if have_tui; then
        p1="$(tui_password "Encryption passphrase" \
            "Enter passphrase for symmetric encryption (used for every archive in this run):")" || rc=$?
        if (( rc != 0 )); then tui_explain_rc "$rc"; exit 1; fi
        p2="$(tui_password "Encryption passphrase" "Confirm passphrase:")" || rc=$?
        if (( rc != 0 )); then tui_explain_rc "$rc"; exit 1; fi
    else
        log_info "symmetric encryption: enter passphrase (used for every archive in this run)"
        printf 'Passphrase: ' >&2; IFS= read -rs p1; printf '\n' >&2
        printf 'Confirm:    ' >&2; IFS= read -rs p2; printf '\n' >&2
    fi

    [[ "$p1" == "$p2" ]] || die "passphrases do not match"
    (( ${#p1} >= 8 ))    || die "passphrase too short (need at least 8 characters)"

    printf '%s' "$p1" >"$PASSPHRASE_FILE"
    log_info "passphrase captured (held in 0600 temp file, shredded on exit)"
}

# Compose gpg args into the named array. Routes around pinentry/TTY issues
# entirely in the symmetric case.
build_gpg_args() {
    local -n _out="$1"
    _out=(--batch --yes --quiet)
    if (( GPG_SYMMETRIC )); then
        _out+=(
            --symmetric
            --cipher-algo AES256
            --pinentry-mode loopback
            --passphrase-file "$PASSPHRASE_FILE"
        )
    else
        _out+=(--encrypt --recipient "$GPG_RECIPIENT" --trust-model always)
    fi
}

# Non-root advisory — when /etc or /root paths are in the section list and
# the user isn't root, rsync will spam "permission denied". Warn once at
# the start so the user knows it's expected (and how to get a complete
# capture).
preflight_root_advisory() {
    [[ $EUID -eq 0 ]] && return 0
    local s want_sudo=0
    for s in "${SECTIONS[@]}"; do
        case "$s" in etc|custom) want_sudo=1 ;; esac
    done
    (( want_sudo )) || return 0

    log_warn "running as non-root: secrets in /etc (shadow, sudoers, NetworkManager system-connections, etc.) are unreadable and will be skipped"
    log_warn "for a complete capture, rerun with sudo:"
    log_warn "  sudo --preserve-env=GNUPGHOME,HOME,GPG_TTY $0 $*"
}

# ---------------------------------------------------------------
# TUI walkthrough — only runs when explicitly requested or when
# the user invoked the script with no flags at all
# ---------------------------------------------------------------
needs_walkthrough() {
    [[ "$USE_TUI" == "yes" ]] && return 0
    [[ "$USE_TUI" == "no"  ]] && return 1
    # auto: walk through if no DEST and we have a TTY
    [[ -z "$DEST" ]] && have_tui
}

run_walkthrough() {
    have_tui || die "no whiptail available; supply --dest and other flags directly (see --help)"
    tui_check_term_size || die "TUI cannot start — see message above (or use --no-tui)"

    log_info "launching TUI walkthrough (Ctrl-C or Esc to abort)"

    local rc out

    # ---- destination ----------------------------------------------------
    out="$(tui_input "Backup destination (1/4)" \
        "Where should the backup go?

Examples:
  /mnt/backup
  file:///mnt/backup
  smb://user@nas.local/backups/witchhammer
  nfs://10.0.0.5/volume1/backups" \
        "${DEST:-}")" || rc=$?
    rc=${rc:-0}
    if (( rc != 0 )); then tui_explain_rc "$rc"; exit 1; fi
    DEST="$out"
    [[ -n "$DEST" ]] || die "no destination provided"

    # ---- sections -------------------------------------------------------
    local -a opts=()
    local s
    for s in "${ALL_SECTIONS[@]}"; do
        opts+=("$s" "" "on")    # whiptail expects lowercase on/off
    done
    rc=0
    out="$(tui_checklist "Sections (2/4)" \
        "Choose what to back up (space toggles, enter confirms):" \
        "${opts[@]}")" || rc=$?
    if (( rc != 0 )); then tui_explain_rc "$rc"; exit 1; fi
    if [[ -z "$out" ]]; then
        die "no sections selected — pick at least one"
    fi
    mapfile -t SECTIONS <<<"$out"

    # ---- encryption mode ------------------------------------------------
    rc=0
    out="$(tui_menu "GPG encryption (3/4)" \
        "How would you like archives encrypted?" \
        "asymmetric" "Use a GPG public key (recipient)" \
        "symmetric"  "Passphrase / AES256")" || rc=$?
    if (( rc != 0 )); then tui_explain_rc "$rc"; exit 1; fi
    if [[ "$out" == "asymmetric" ]]; then
        rc=0
        out="$(tui_input "GPG recipient" \
            "Enter the recipient (key ID, fingerprint, or email):" \
            "${GPG_RECIPIENT:-}")" || rc=$?
        if (( rc != 0 )); then tui_explain_rc "$rc"; exit 1; fi
        [[ -n "$out" ]] || die "no GPG recipient provided"
        GPG_RECIPIENT="$out"
    else
        GPG_SYMMETRIC=1
    fi

    # ---- final go/no-go -------------------------------------------------
    rc=0
    out="$(tui_menu "Run mode (4/4)" \
        "Final step. Dry-run is the safe default — pick EXECUTE only when you've reviewed the plan." \
        "dry-run"  "Preview only (no files written) [default]" \
        "execute"  "Write the backup")" || rc=$?
    if (( rc != 0 )); then tui_explain_rc "$rc"; exit 1; fi
    [[ "$out" == "execute" ]] && DRY_RUN=0

    log_info "TUI walkthrough complete: dest=$DEST sections=(${SECTIONS[*]}) mode=$(dry_label)"
}

# ---------------------------------------------------------------
# validation
# ---------------------------------------------------------------
validate_args() {
    [[ -n "$DEST" ]]     || die "missing required --dest  (try --help)"
    if (( ! GPG_SYMMETRIC )) && [[ -z "$GPG_RECIPIENT" ]]; then
        die "encryption not configured: pass --gpg-recipient ID or --gpg-symmetric"
    fi
    if [[ -n "$GPG_RECIPIENT" ]] && (( GPG_SYMMETRIC )); then
        die "--gpg-recipient and --gpg-symmetric are mutually exclusive"
    fi
    if ! [[ "$ZSTD_LEVEL" =~ ^[0-9]+$ ]] || (( ZSTD_LEVEL < 1 || ZSTD_LEVEL > 22 )); then
        die "--zstd-level must be 1..22 (got: $ZSTD_LEVEL)"
    fi
    if [[ -n "$LINK_DEST" && ! -d "$LINK_DEST" ]]; then
        die "--link-dest does not exist or is not a directory: $LINK_DEST"
    fi
    if [[ -n "$SMB_CREDENTIALS" && ! -r "$SMB_CREDENTIALS" ]]; then
        die "cannot read --smb-credentials file: $SMB_CREDENTIALS"
    fi
    # Verify GPG recipient resolves to a usable public key
    if [[ -n "$GPG_RECIPIENT" ]] && ! dry; then
        gpg --list-keys --with-colons "$GPG_RECIPIENT" &>/dev/null \
            || die "gpg cannot find a public key for: $GPG_RECIPIENT"
    fi
}

# ---------------------------------------------------------------
# section: package inventories
# ---------------------------------------------------------------
section_packages() {
    local out="$1/packages"
    mkdir_p "$out"
    log_info "[packages] taking inventories"

    # APT (Debian/Ubuntu/Pop)
    if have_cmd apt-mark; then
        run_capture "$out/apt-manual.txt"     apt-mark showmanual
        run_capture "$out/apt-selections.txt" dpkg --get-selections
    fi
    if have_cmd add-apt-repository && [[ -d /etc/apt/sources.list.d ]]; then
        # A copy of sources is captured by /etc, but stash a small text dump
        # here too for quick grep without decrypting.
        if dry; then
            log_dry "tar -C / -cf $out/apt-sources.tar etc/apt/sources.list etc/apt/sources.list.d etc/apt/keyrings etc/apt/trusted.gpg.d"
        else
            tar --ignore-failed-read -C / -cf "$out/apt-sources.tar" \
                etc/apt/sources.list \
                etc/apt/sources.list.d \
                etc/apt/keyrings \
                etc/apt/trusted.gpg.d 2>/dev/null || true
        fi
    fi

    # DNF / YUM
    if have_cmd dnf; then
        run_capture "$out/dnf-userinstalled.txt" dnf repoquery --userinstalled --qf '%{name}'
        run_capture "$out/dnf-history.txt"       dnf history list
    elif have_cmd yum; then
        run_capture "$out/yum-installed.txt" yum list installed
    fi

    # Pacman (Arch / Manjaro)
    if have_cmd pacman; then
        run_capture "$out/pacman-explicit.txt" pacman -Qqe
        run_capture "$out/pacman-foreign.txt"  pacman -Qqm
    fi

    # Zypper (openSUSE)
    if have_cmd zypper; then
        run_capture "$out/zypper-installed.txt" zypper search --installed-only --type package
    fi

    # Apk (Alpine)
    if have_cmd apk; then
        run_capture "$out/apk-world.txt" apk info -e
    fi

    # Flatpak
    if have_cmd flatpak; then
        run_capture "$out/flatpak.txt" \
            flatpak list --columns=application,origin,branch,arch --app
        run_capture "$out/flatpak-runtimes.txt" \
            flatpak list --columns=application,origin,branch,arch --runtime
        run_capture "$out/flatpak-remotes.txt" \
            flatpak remotes --columns=name,url
    fi

    # Snap
    if have_cmd snap; then
        run_capture "$out/snap.txt" snap list
    fi

    # pipx
    if have_cmd pipx; then
        run_capture "$out/pipx.txt" pipx list --short
    fi

    # cargo
    if have_cmd cargo; then
        run_capture "$out/cargo.txt" cargo install --list
    fi

    # rustup
    if have_cmd rustup; then
        run_capture "$out/rustup-toolchains.txt" rustup toolchain list
    fi

    # go (read modules baked into binaries under $GOPATH/bin)
    if have_cmd go; then
        local gopath
        gopath="$(go env GOPATH 2>/dev/null || true)"
        : "${gopath:=$HOME/go}"
        if [[ -d "$gopath/bin" ]]; then
            local -a bins=()
            mapfile -t bins < <(find "$gopath/bin" -maxdepth 1 -type f -executable 2>/dev/null)
            if (( ${#bins[@]} )); then
                if dry; then
                    log_dry "go version -m ${bins[*]} > $out/go.txt"
                else
                    go version -m "${bins[@]}" 2>/dev/null \
                        | awk '/^\tpath\t/ {print $2}' \
                        | sort -u >"$out/go.txt" || true
                fi
            fi
        fi
    fi

    # npm globals (best-effort; npm prints to stderr without --silent)
    if have_cmd npm; then
        run_capture "$out/npm-global.txt" npm ls -g --depth=0 --silent
    fi

    # gem
    if have_cmd gem; then
        run_capture "$out/gem-user.txt" gem list --no-versions
    fi

    # asdf
    if have_cmd asdf; then
        run_capture "$out/asdf-current.txt" asdf current
        run_capture "$out/asdf-plugins.txt" asdf plugin list --urls
    fi

    log_ok "[packages] done"
}

# ---------------------------------------------------------------
# section: desktop / session
# ---------------------------------------------------------------
section_desktop() {
    local out="$1/desktop"
    mkdir_p "$out"
    log_info "[desktop] capturing session metadata"

    if dry; then
        log_dry "write $out/session.env"
    else
        cat >"$out/session.env" <<EOF
XDG_CURRENT_DESKTOP=${XDG_CURRENT_DESKTOP:-}
XDG_SESSION_DESKTOP=${XDG_SESSION_DESKTOP:-}
XDG_SESSION_TYPE=${XDG_SESSION_TYPE:-}
DESKTOP_SESSION=${DESKTOP_SESSION:-}
GDMSESSION=${GDMSESSION:-}
WAYLAND_DISPLAY=${WAYLAND_DISPLAY:-}
DISPLAY=${DISPLAY:-}
EOF
    fi

    have_cmd dconf            && run_capture "$out/dconf-dump.ini"      dconf dump /
    have_cmd gnome-extensions && run_capture "$out/gnome-extensions.txt" gnome-extensions list --enabled
    have_cmd gsettings        && run_capture "$out/gsettings-schemas.txt" gsettings list-schemas
    have_cmd kwriteconfig5    && run_capture "$out/kde-version.txt"     kwriteconfig5 --help

    # Common WM/DE detect (non-fatal probes)
    if have_cmd loginctl; then
        run_capture "$out/loginctl-sessions.txt" loginctl list-sessions --no-legend
    fi
    if have_cmd xrdb && [[ -n "${DISPLAY:-}" ]]; then
        run_capture "$out/xrdb-query.txt" xrdb -query
    fi

    log_ok "[desktop] done"
}

# ---------------------------------------------------------------
# section: system snapshot
# ---------------------------------------------------------------
section_system() {
    local out="$1/system"
    mkdir_p "$out"
    log_info "[system] capturing hardware/OS state"

    run_capture "$out/uname.txt"          uname -a
    [[ -r /etc/os-release  ]] && run cp /etc/os-release  "$out/os-release"
    [[ -r /etc/lsb-release ]] && run cp /etc/lsb-release "$out/lsb-release"
    [[ -r /etc/fstab       ]] && run cp /etc/fstab       "$out/fstab"
    [[ -r /etc/hosts       ]] && run cp /etc/hosts       "$out/hosts"
    [[ -r /etc/resolv.conf ]] && run cp /etc/resolv.conf "$out/resolv.conf"
    [[ -r /proc/cmdline    ]] && run_capture "$out/cmdline.txt"   cat /proc/cmdline

    have_cmd lsblk        && run_capture "$out/lsblk.txt"           lsblk -f
    have_cmd lspci        && run_capture "$out/lspci.txt"           lspci -nnv
    have_cmd lsusb        && run_capture "$out/lsusb.txt"           lsusb
    have_cmd lsmod        && run_capture "$out/lsmod.txt"           lsmod
    have_cmd ip           && run_capture "$out/ip-addr.txt"         ip -o addr
    have_cmd ip           && run_capture "$out/ip-route.txt"        ip -o route
    have_cmd efibootmgr   && run_capture "$out/efibootmgr.txt"      efibootmgr -v
    have_cmd timedatectl  && run_capture "$out/timedatectl.txt"     timedatectl show
    have_cmd hostnamectl  && run_capture "$out/hostnamectl.txt"     hostnamectl
    have_cmd systemctl    && run_capture "$out/systemd-units.txt"   systemctl list-unit-files --no-pager
    have_cmd systemctl    && run_capture "$out/systemd-enabled.txt" systemctl list-unit-files --state=enabled --no-pager
    have_cmd systemctl    && run_capture "$out/systemd-user.txt"    systemctl --user list-unit-files --no-pager

    log_ok "[system] done"
}

# ---------------------------------------------------------------
# section: archive — common path used by etc/home/custom
# ---------------------------------------------------------------
archive_section() {
    # archive_section <name> <session_dir> <src_paths...>
    # 1. rsync sources into <session>/staging/<name>/<original-path>
    # 2. tar that staging tree, pipe through zstd + gpg, write archive
    # 3. (unless --keep-staging) remove staging
    local name="$1"; shift
    local session_dir="$1"; shift
    local -a srcs=("$@")
    local staging="$session_dir/staging/$name"
    local archive="$session_dir/configs/${name}.tar.zst.gpg"

    # Filter to existing source paths so missing /opt etc. don't abort
    local -a present=()
    local s
    for s in "${srcs[@]}"; do
        if [[ -e "$s" ]]; then
            present+=("$s")
        else
            log_warn "[$name] skipping non-existent source: $s"
        fi
    done
    if (( ${#present[@]} == 0 )); then
        log_warn "[$name] no sources to archive — skipping section"
        return 0
    fi

    mkdir_p "$staging" "$session_dir/configs"

    log_info "[$name] rsync staging → $staging"

    local -a rsync_args=(
        --archive
        --acls
        --xattrs
        --hard-links
        --sparse
        --numeric-ids
        --relative
        --info=stats1
    )
    [[ "$VERBOSE" == 1 ]] && rsync_args+=(--verbose)
    [[ -f "$SCRIPT_DIR/excludes-common.txt" ]] \
        && rsync_args+=(--exclude-from="$SCRIPT_DIR/excludes-common.txt")
    case "$name" in
        home)
            [[ -f "$SCRIPT_DIR/excludes-home.txt" ]] \
                && rsync_args+=(--exclude-from="$SCRIPT_DIR/excludes-home.txt")
            ;;
        etc)
            [[ -f "$SCRIPT_DIR/excludes-system.txt" ]] \
                && rsync_args+=(--exclude-from="$SCRIPT_DIR/excludes-system.txt")
            ;;
        custom)
            [[ -f "$SCRIPT_DIR/excludes-system.txt" ]] \
                && rsync_args+=(--exclude-from="$SCRIPT_DIR/excludes-system.txt")
            ;;
    esac
    if [[ -n "$LINK_DEST" && -d "$LINK_DEST/staging/$name" ]]; then
        rsync_args+=(--link-dest="$LINK_DEST/staging/$name")
    fi

    if dry; then
        log_dry "rsync ${rsync_args[*]} ${present[*]} $staging/"
    else
        local rsync_rc=0
        rsync "${rsync_args[@]}" "${present[@]}" "$staging/" || rsync_rc=$?
        case "$rsync_rc" in
            0)  ;;
            23) log_warn "[$name] rsync: some files unreadable (permission denied) or vanished — they were skipped. Continuing with what did transfer." ;;
            24) log_warn "[$name] rsync: some source files vanished during transfer — they were skipped. Continuing." ;;
            *)  die "[$name] rsync failed with exit code $rsync_rc" ;;
        esac
    fi

    log_info "[$name] tar | zstd -$ZSTD_LEVEL | gpg → $archive"

    if dry; then
        log_dry "tar -C $staging -cf - . | zstd -$ZSTD_LEVEL -T0 | gpg ... > $archive"
    else
        local -a gpg_args
        build_gpg_args gpg_args
        # pipefail is on at script level; no subshell needed (it just causes
        # the ERR trap to fire twice on failure).
        tar --xattrs --acls --numeric-owner -C "$staging" -cf - . \
            | zstd "-$ZSTD_LEVEL" -T0 -q \
            | gpg "${gpg_args[@]}" --output "$archive"
        chmod 0400 "$archive"
    fi

    if (( ! KEEP_STAGING )); then
        log_info "[$name] removing staging"
        run rm -rf "$staging"
    fi

    log_ok "[$name] done"
}

# ---------------------------------------------------------------
# encrypt-all: wrap inventories into a single encrypted archive
# ---------------------------------------------------------------
encrypt_inventories() {
    local session_dir="$1"
    local archive="$session_dir/configs/inventories.tar.zst.gpg"
    mkdir_p "$session_dir/configs"

    local -a present=()
    local d
    for d in packages desktop system; do
        [[ -d "$session_dir/$d" ]] && present+=("$d")
    done
    if (( ${#present[@]} == 0 )); then
        log_info "[encrypt-all] no inventory dirs present — skipping"
        return 0
    fi

    log_info "[encrypt-all] tar | zstd | gpg → $archive  (sources: ${present[*]})"
    if dry; then
        log_dry "tar -C $session_dir -cf - ${present[*]} | zstd -$ZSTD_LEVEL -T0 | gpg ... > $archive"
        return 0
    fi
    local -a gpg_args
    build_gpg_args gpg_args
    tar -C "$session_dir" -cf - "${present[@]}" \
        | zstd "-$ZSTD_LEVEL" -T0 -q \
        | gpg "${gpg_args[@]}" --output "$archive"
    chmod 0400 "$archive"

    log_info "[encrypt-all] removing plain-text inventories"
    local p
    for p in "${present[@]}"; do
        run rm -rf "$session_dir/$p"
    done
}

# ---------------------------------------------------------------
# manifest, checksums, signature, immutability
# ---------------------------------------------------------------
write_manifest() {
    local session_dir="$1"
    local file="$session_dir/manifest.json"
    log_info "writing manifest"

    if dry; then
        log_dry "write $file"
        return 0
    fi

    local hostname kernel total_bytes
    hostname="$(hostname 2>/dev/null || echo unknown)"
    kernel="$(uname -r)"
    total_bytes="$(du -sb "$session_dir" 2>/dev/null | awk '{print $1}')"

    {
        printf '{\n'
        printf '  "version": "%s",\n'      "$VERSION"
        printf '  "tool": "%s",\n'         "$SCRIPT"
        printf '  "hostname": "%s",\n'     "$hostname"
        printf '  "kernel": "%s",\n'       "$kernel"
        printf '  "user": "%s",\n'         "${USER:-$(id -un)}"
        printf '  "started_at": "%s",\n'   "${SESSION_STARTED_AT:-}"
        printf '  "completed_at": "%s",\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
        printf '  "destination": "%s",\n'  "$session_dir"
        printf '  "sections": ['
        local first=1 s
        for s in "${SECTIONS[@]}"; do
            (( first )) || printf ', '
            printf '"%s"' "$s"
            first=0
        done
        printf '],\n'
        printf '  "encryption": "%s",\n'   "$( (( GPG_SYMMETRIC )) && echo gpg-symmetric || echo gpg-asymmetric )"
        printf '  "gpg_recipient": "%s",\n' "${GPG_RECIPIENT}"
        printf '  "zstd_level": %s,\n'     "$ZSTD_LEVEL"
        printf '  "link_dest": "%s",\n'    "${LINK_DEST}"
        printf '  "total_bytes": %s\n'    "${total_bytes:-0}"
        printf '}\n'
    } >"$file"

    if have_cmd jq; then
        local tmp; tmp="$(mktemp)"
        jq . "$file" >"$tmp" && mv "$tmp" "$file"
    fi
    chmod 0444 "$file"
}

write_checksums() {
    local session_dir="$1"
    local file="$session_dir/SHA256SUMS"
    log_info "computing SHA256SUMS"
    if dry; then
        log_dry "sha256sum (recursive) > $file"
        return 0
    fi
    sha256_dir "$session_dir" >"$file"
    chmod 0444 "$file"
}

sign_checksums() {
    local session_dir="$1"
    local file="$session_dir/SHA256SUMS"
    local sig="$session_dir/SHA256SUMS.sig"

    if (( GPG_SYMMETRIC )); then
        log_info "skipping signature (symmetric mode has no signing key context)"
        return 0
    fi
    log_info "signing SHA256SUMS with gpg detached signature"
    if dry; then
        log_dry "gpg --detach-sign --armor --local-user $GPG_RECIPIENT $file"
        return 0
    fi
    gpg --batch --yes --armor --detach-sign \
        --local-user "$GPG_RECIPIENT" \
        --output "$sig" \
        "$file" \
        || log_warn "could not sign SHA256SUMS (no secret key for $GPG_RECIPIENT?)"
    [[ -f "$sig" ]] && chmod 0444 "$sig"
}

apply_immutable() {
    local session_dir="$1"
    log_info "setting chattr +i on archives (requires root, ext*/xfs/btrfs only)"
    if dry; then
        log_dry "sudo chattr +i $session_dir/configs/*.gpg $session_dir/SHA256SUMS*"
        return 0
    fi
    sudo chattr +i "$session_dir"/configs/*.gpg \
                   "$session_dir"/SHA256SUMS \
                   "$session_dir"/SHA256SUMS.sig 2>/dev/null \
        || log_warn "chattr +i failed (filesystem may not support it; not fatal)"
}

# ---------------------------------------------------------------
# summary printer
# ---------------------------------------------------------------
print_summary() {
    local session_dir="$1"
    local size_text="?"
    if [[ -d "$session_dir" ]]; then
        local b
        b="$(du -sb "$session_dir" 2>/dev/null | awk '{print $1}')"
        [[ -n "$b" ]] && size_text="$(human_bytes "$b")"
    fi

    printf '\n'
    printf '%s═══ backup summary ═══%s\n' "$C_BLU" "$C_RST"
    printf '  mode         : %s\n' "$(dry_label)"
    printf '  hostname     : %s\n' "$(hostname 2>/dev/null || echo unknown)"
    printf '  destination  : %s\n' "$session_dir"
    printf '  sections     : %s\n' "${SECTIONS[*]}"
    printf '  encryption   : %s\n' "$( (( GPG_SYMMETRIC )) && echo "gpg symmetric (AES256)" \
                                                       || echo "gpg recipient $GPG_RECIPIENT" )"
    printf '  zstd level   : %s\n' "$ZSTD_LEVEL"
    printf '  total size   : %s\n' "$size_text"
    if dry; then
        printf '  %sno files were written. Re-run with --execute to perform the backup.%s\n' "$C_YEL" "$C_RST"
    fi
    printf '\n'
    printf 'Verification commands (raw CLI, copy/paste-able):\n'
    printf "  cd '%s' && sha256sum --check SHA256SUMS\n" "$session_dir"
    if (( ! GPG_SYMMETRIC )); then
        printf "  gpg --verify '%s/SHA256SUMS.sig' '%s/SHA256SUMS'\n" "$session_dir" "$session_dir"
    fi
    printf "  gpg --decrypt '%s/configs/home.tar.zst.gpg' | zstd -d | tar -tvf - | head\n" "$session_dir"
    printf '\n'
}

# ---------------------------------------------------------------
# main
# ---------------------------------------------------------------
main() {
    local -a original_argv=("$@")

    parse_args "$@"

    if (( DEBUG )); then
        log_info "debug mode: enabling shell trace"
        export PS4='+ ${BASH_SOURCE##*/}:${LINENO}: '
        set -x
    fi

    configure_gpg_env

    if needs_walkthrough; then
        run_walkthrough
    fi

    validate_args
    detect_tools
    preflight_root_advisory "${original_argv[@]}"
    setup_passphrase

    resolve_dest "$DEST"
    DEST="${DEST%/}"                       # strip trailing slash so paths don't end up like /path//session
    [[ -d "$DEST" ]] || mkdir_p "$DEST"

    SESSION_STARTED_AT="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
    local session_name session_dir
    session_name="$(hostname 2>/dev/null || echo host)-$(date -u +%Y-%m-%dT%H%M%SZ)"
    session_dir="$DEST/$session_name"
    mkdir_p "$session_dir"

    log_info "session: $session_dir"
    log_info "mode:    $(dry_label)"
    if dry; then
        log_warn "DRY RUN — no files will be written. Pass --execute to commit."
    fi

    # Run requested sections
    local s
    for s in "${SECTIONS[@]}"; do
        case "$s" in
            packages) section_packages "$session_dir" ;;
            desktop)  section_desktop  "$session_dir" ;;
            system)   section_system   "$session_dir" ;;
            etc)      archive_section  etc    "$session_dir" /etc ;;
            home)     archive_section  home   "$session_dir" "$HOME" ;;
            custom)   archive_section  custom "$session_dir" "${CUSTOM_PATHS[@]}" ;;
            *)        log_warn "unknown section: $s (ignored)" ;;
        esac
    done

    # Optional: encrypt the plain-text inventories too
    if (( ENCRYPT_ALL )); then
        encrypt_inventories "$session_dir"
    fi

    write_manifest   "$session_dir"
    write_checksums  "$session_dir"
    sign_checksums   "$session_dir"
    if (( IMMUTABLE )); then
        apply_immutable "$session_dir"
    fi

    if ! dry; then
        chmod 0500 "$session_dir" 2>/dev/null || true
    fi

    print_summary "$session_dir"
    log_ok "backup complete"
}

main "$@"

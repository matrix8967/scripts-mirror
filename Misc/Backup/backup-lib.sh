#!/usr/bin/env bash
# backup-lib.sh — shared helpers for backup-system.sh and restore-system.sh.
# Source this file; do not execute it directly.
#
# Conventions:
#   - All log_* output goes to stderr so stdout is reserved for tool data.
#   - Functions are pure-bash where practical and avoid external commands
#     in tight loops.
#   - DRY_RUN=1 (default in callers) gates every state-mutating action via
#     run() / run_capture().

# guard against double-source
[[ -n "${_SCROLLS_BACKUP_LIB:-}" ]] && return 0
_SCROLLS_BACKUP_LIB=1

# ---------------------------------------------------------------
# colour
# ---------------------------------------------------------------
if [[ -t 2 && -z "${NO_COLOR:-}" ]]; then
    C_RED=$'\033[31m'
    C_YEL=$'\033[33m'
    C_GRN=$'\033[32m'
    C_BLU=$'\033[34m'
    C_DIM=$'\033[2m'
    C_RST=$'\033[0m'
else
    C_RED="" C_YEL="" C_GRN="" C_BLU="" C_DIM="" C_RST=""
fi

log_info()  { printf '%s[info]%s %s\n' "$C_BLU" "$C_RST" "$*" >&2; }
log_warn()  { printf '%s[warn]%s %s\n' "$C_YEL" "$C_RST" "$*" >&2; }
log_error() { printf '%s[err ]%s %s\n' "$C_RED" "$C_RST" "$*" >&2; }
log_ok()    { printf '%s[ ok ]%s %s\n' "$C_GRN" "$C_RST" "$*" >&2; }
log_dry()   { printf '%s[dry ]%s %s\n' "$C_DIM" "$C_RST" "$*" >&2; }
log_cmd()   { printf '%s[ $ ]%s %s\n' "$C_DIM" "$C_RST" "$*" >&2; }

die() { log_error "$*"; exit 1; }

require_cmd() {
    # require_cmd <cmd> [pkg-hint]
    local cmd="$1"
    local pkg="${2:-$1}"
    command -v "$cmd" &>/dev/null \
        || die "missing command: $cmd  (try installing: $pkg)"
}

have_cmd() { command -v "$1" &>/dev/null; }

dry()       { (( ${DRY_RUN:-1} == 1 )); }
dry_label() { dry && printf 'DRY RUN' || printf 'EXECUTE'; }

# ---------------------------------------------------------------
# run helpers — every disk-touching call routes through here
# ---------------------------------------------------------------
run() {
    if dry; then
        log_dry "$*"
        return 0
    fi
    (( ${VERBOSE:-0} )) && log_cmd "$*"
    "$@"
}

run_capture() {
    # run_capture <out_file> <cmd...>
    # Captures stdout to file. Stderr is suppressed; failure is logged but
    # non-fatal so a single missing tool does not abort the whole backup.
    local out="$1"; shift
    if dry; then
        log_dry "$* > $out"
        return 0
    fi
    (( ${VERBOSE:-0} )) && log_cmd "$* > $out"
    if ! "$@" >"$out" 2>/dev/null; then
        log_warn "(non-fatal) command failed, leaving $out empty: $*"
        : >"$out"
        return 0
    fi
}

mkdir_p() { run mkdir -p "$@"; }

# ---------------------------------------------------------------
# TUI helpers (whiptail; degrade to plain prompts if absent)
# ---------------------------------------------------------------
# Each tui_* function:
#   - writes the user's choice (if any) to stdout
#   - returns 0 on OK, 1 on Cancel, 2 on Esc, 3 on size/runtime error
#   - captures whiptail's exit code explicitly so set -e never silently
#     swallows a Cancel/Esc inside a command substitution
have_tui() {
    [[ "${USE_TUI:-auto}" == "no" ]] && return 1
    [[ "${USE_TUI:-auto}" == "yes" ]] && return 0
    have_cmd whiptail && [[ -t 0 && -t 1 && -t 2 ]]
}

# Whiptail wants at least height 24, width 80. Without this, dialogs may
# launch and immediately close on small terminals — the failure mode that
# looks like "TUI exits silently".
tui_check_term_size() {
    local rows cols
    if [[ -n "${LINES:-}" && -n "${COLUMNS:-}" ]]; then
        rows="$LINES"; cols="$COLUMNS"
    else
        read -r rows cols < <(stty size 2>/dev/null || echo "0 0")
    fi
    if (( rows < 24 || cols < 80 )); then
        log_error "terminal too small for TUI: ${rows}x${cols} (need at least 24x80)"
        log_error "either resize the terminal or pass --no-tui with explicit flags"
        return 1
    fi
    return 0
}

# Internal: run whiptail and capture (stdout-from-stderr-swap, exit-code).
# Caller passes whiptail args; we redirect so the result text is on fd 1.
_whiptail() {
    local rc=0 out
    out="$(whiptail "$@" 3>&1 1>&2 2>&3)" || rc=$?
    case "$rc" in
        0)   printf '%s' "$out"; return 0 ;;
        1)   return 1 ;;     # Cancel
        255) return 2 ;;     # ESC
        *)   log_error "whiptail returned unexpected exit code $rc"; return 3 ;;
    esac
}

tui_msg()      { whiptail --title "$1" --msgbox  "$2" 14 78 || true; }
tui_yesno()    { whiptail --title "$1" --yesno   "$2" 14 78; }
tui_input()    { _whiptail --title "$1" --inputbox    "$2" 14 78 "${3:-}"; }
tui_password() { _whiptail --title "$1" --passwordbox "$2" 14 78; }
tui_menu() {
    local title="$1" prompt="$2"; shift 2
    _whiptail --title "$title" --menu "$prompt" 22 78 14 "$@"
}
tui_checklist() {
    local title="$1" prompt="$2"; shift 2
    _whiptail --title "$title" --checklist "$prompt" 22 78 14 \
        --separate-output "$@"
}

# Pretty wrapper: explain why the TUI bailed in user-readable terms, so
# the script never exits silently after a cancelled prompt.
tui_explain_rc() {
    case "${1:-0}" in
        0) ;;
        1) log_warn "TUI: cancelled" ;;
        2) log_warn "TUI: closed (Esc)" ;;
        3) log_error "TUI: whiptail failed unexpectedly — see error above" ;;
        *) log_error "TUI: unexpected return code $1" ;;
    esac
}

# ---------------------------------------------------------------
# cleanup hooks — multiple cleanups can register without clobbering
# each other (a single EXIT/INT/TERM/HUP trap calls them all in order)
# ---------------------------------------------------------------
declare -ga _CLEANUP_HOOKS=()
add_cleanup_hook() { _CLEANUP_HOOKS+=("$1"); }
_run_cleanup_hooks() {
    local hook
    for hook in "${_CLEANUP_HOOKS[@]}"; do
        # shellcheck disable=SC2086  # hook is a single function name
        $hook || true
    done
}
trap _run_cleanup_hooks EXIT
trap 'log_warn "interrupted (SIGINT)"; exit 130' INT
trap 'exit 143' TERM
trap 'exit 129' HUP

# ---------------------------------------------------------------
# destination URL handling (file://, smb://, cifs://, nfs://, plain path)
# ---------------------------------------------------------------
REMOTE_MOUNT_DIR=""
REMOTE_MOUNTED=0

cleanup_remote_mount() {
    if (( REMOTE_MOUNTED )); then
        log_info "unmounting remote: $REMOTE_MOUNT_DIR"
        sudo umount "$REMOTE_MOUNT_DIR" 2>/dev/null \
            || sudo umount -l "$REMOTE_MOUNT_DIR" 2>/dev/null \
            || true
        rmdir "$REMOTE_MOUNT_DIR" 2>/dev/null || true
        REMOTE_MOUNTED=0
    fi
}

mount_remote() {
    # mount_remote <url>
    # On success sets MOUNTED_DEST to a usable local path.
    local url="$1"
    local scheme rest
    scheme="${url%%://*}"
    rest="${url#*://}"

    REMOTE_MOUNT_DIR="$(mktemp -d -t scrolls-bk-mnt.XXXXXX)"
    add_cleanup_hook cleanup_remote_mount

    case "$scheme" in
        smb|cifs)
            local userpart="" hostpath="$rest"
            if [[ "$hostpath" == *"@"* ]]; then
                userpart="${hostpath%%@*}"
                hostpath="${hostpath#*@}"
            fi
            local host="${hostpath%%/*}"
            local sharepath="${hostpath#*/}"
            local share="${sharepath%%/*}"
            local subpath=""
            [[ "$sharepath" == */* ]] && subpath="/${sharepath#*/}"

            require_cmd mount.cifs cifs-utils
            local uid gid opts
            uid="$(id -u)"
            gid="$(id -g)"
            opts="rw,uid=${uid},gid=${gid},iocharset=utf8,vers=3.0"
            if [[ -n "${SMB_CREDENTIALS:-}" ]]; then
                opts+=",credentials=$SMB_CREDENTIALS"
            elif [[ -n "$userpart" ]]; then
                opts+=",username=$userpart"
            fi

            if dry; then
                log_dry "sudo mount -t cifs //${host}/${share} $REMOTE_MOUNT_DIR -o $opts"
                MOUNTED_DEST="$REMOTE_MOUNT_DIR$subpath"
                return 0
            fi

            log_info "mounting //${host}/${share} → $REMOTE_MOUNT_DIR"
            sudo mount -t cifs "//${host}/${share}" "$REMOTE_MOUNT_DIR" -o "$opts" \
                || die "cifs mount failed (//${host}/${share})"
            REMOTE_MOUNTED=1
            MOUNTED_DEST="$REMOTE_MOUNT_DIR$subpath"
            mkdir -p "$MOUNTED_DEST" \
                || die "could not create $MOUNTED_DEST under remote share"
            ;;
        nfs)
            local host="${rest%%/*}"
            local subpath="/${rest#*/}"
            require_cmd mount.nfs nfs-common
            if dry; then
                log_dry "sudo mount -t nfs ${host}:${subpath} $REMOTE_MOUNT_DIR"
                MOUNTED_DEST="$REMOTE_MOUNT_DIR"
                return 0
            fi
            log_info "mounting ${host}:${subpath} → $REMOTE_MOUNT_DIR"
            sudo mount -t nfs "${host}:${subpath}" "$REMOTE_MOUNT_DIR" \
                || die "nfs mount failed (${host}:${subpath})"
            REMOTE_MOUNTED=1
            MOUNTED_DEST="$REMOTE_MOUNT_DIR"
            ;;
        file)
            MOUNTED_DEST="$rest"
            ;;
        *)
            die "unknown destination scheme: $scheme  (expected file://, smb://, cifs://, nfs://, or a plain local path)"
            ;;
    esac
}

resolve_dest() {
    # Translate a user-supplied destination into a local path; mounts remote
    # filesystems on demand. Sets DEST (consumed by the calling script).
    local raw="$1"
    # shellcheck disable=SC2034  # DEST is consumed by sourcing scripts
    if [[ "$raw" =~ ^(smb|cifs|nfs|file):// ]]; then
        mount_remote "$raw"
        DEST="$MOUNTED_DEST"
    else
        DEST="$raw"
    fi
}

# ---------------------------------------------------------------
# hashing & manifest helpers
# ---------------------------------------------------------------
sha256_dir() {
    # sha256_dir <root>  → emits sha256sum lines for every regular file
    # under <root>, with paths relative to <root>. Output suitable for
    # `sha256sum --check` from inside <root>.
    local root="$1"
    ( cd "$root" && find . -type f \! -name SHA256SUMS \! -name SHA256SUMS.sig \
        -print0 | LC_ALL=C sort -z \
        | xargs -0 sha256sum )
}

human_bytes() {
    # human_bytes <bytes>
    local b="${1:-0}"
    if have_cmd numfmt; then
        numfmt --to=iec-i --suffix=B --format='%.1f' "$b"
    elif   (( b >= 1073741824 )); then awk -v b="$b" 'BEGIN{printf "%.1fG", b/1073741824}'
    elif   (( b >= 1048576 ));    then awk -v b="$b" 'BEGIN{printf "%.1fM", b/1048576}'
    elif   (( b >= 1024 ));       then awk -v b="$b" 'BEGIN{printf "%.1fK", b/1024}'
    else printf '%dB' "$b"
    fi
}

# ---------------------------------------------------------------
# self-test (run only when executed directly, never when sourced)
# ---------------------------------------------------------------
if [[ "${BASH_SOURCE[0]}" == "${0:-}" ]]; then
    cat >&2 <<'EOF'
backup-lib.sh is a shared library; source it from backup-system.sh or
restore-system.sh rather than running it directly.
EOF
    exit 64
fi

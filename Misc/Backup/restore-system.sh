#!/usr/bin/env bash
# restore-system.sh — companion to backup-system.sh.
#
# Subcommands:
#   list      Enumerate backup sessions in a destination directory.
#   inspect   Read manifest + listing of an archive without decrypting it.
#   verify    Validate SHA256SUMS and (if present) the GPG detached signature.
#   packages  Replay package inventories on the current system.
#   configs   Decrypt config archives into a scratch dir; optionally apply.
#
# Default mode is --dry-run; pass --execute to actually mutate the system.
# Run `./restore-system.sh --help` for full usage.

set -Eeuo pipefail

VERSION="0.1.0"
SCRIPT="$(basename "$0")"
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"

# shellcheck source=backup-lib.sh
source "$SCRIPT_DIR/backup-lib.sh"

on_err() {
    local rc=$?
    log_error "errexit at ${BASH_SOURCE[1]:-?}:${BASH_LINENO[0]:-?} — \"${BASH_COMMAND}\" (rc=$rc)"
    exit "$rc"
}
trap on_err ERR

# ---------------------------------------------------------------
# defaults
# ---------------------------------------------------------------
DRY_RUN=1
DEST=""
SESSION=""
SCRATCH=""
APPLY_IN_PLACE=0
USE_TUI="auto"
VERBOSE=0
SMB_CREDENTIALS=""
declare -a INCLUDE=()
declare -a SKIP=()
declare -a ARCHIVES=()    # for `configs` subcommand: which archives to extract

usage() {
    cat <<EOF
$SCRIPT v$VERSION — restore from a backup-system.sh session

USAGE
    $SCRIPT <subcommand> [options]

SUBCOMMANDS
    list                       List sessions inside a backup destination.
    inspect <session-dir>      Show manifest, sizes, and unencrypted contents.
    verify  <session-dir>      Check SHA256SUMS + GPG signature (if any).
    packages <session-dir>     Reinstall packages from the inventories.
    configs  <session-dir>     Extract config archives, stage them, optionally
                               apply. Auto-detects .tar.zst.gpg (encrypted)
                               and .tar.zst (plain, --no-encrypt backups).

GLOBAL OPTIONS
    --dest PATH                Destination root (only required for 'list' or
                               when <session-dir> is a remote URL).
                               Accepts the same schemes as backup-system.sh:
                               file://, smb://, cifs://, nfs://, plain path.
    --smb-credentials FILE     CIFS credentials file (when --dest is smb://).
    --tui                      Force interactive whiptail flow (configs).
    --no-tui                   Force non-interactive.
    -v, --verbose
    -h, --help
    --version

SAFETY
    --dry-run                  Default. Print actions, don't run them.
    --execute                  Actually run the action (install, copy, etc.).

PACKAGES OPTIONS
    --include LIST             Comma-separated managers to replay.
                               apt | dnf | pacman | flatpak | pipx | cargo | go | snap
                               Default: all that are present in the backup
                               AND on the current system.
    --skip LIST                Comma-separated managers to skip.

CONFIGS OPTIONS
    --archives LIST            Comma-separated archives to decrypt.
                               etc | home | custom | inventories
                               Default: all present.
    --scratch DIR              Where to extract decrypted contents.
                               Default: \$XDG_RUNTIME_DIR/scrolls-restore-<ts>/
    --apply-in-place           DANGEROUS. After staging, copy files directly
                               into / (etc → /etc, home → \$HOME, etc.).
                               Without this flag, the script only stages and
                               prints a diff summary.

EXAMPLES

  List sessions on a remote share (no auth state changes):
      $SCRIPT list --dest smb://nas.local/backups/witchhammer \\
                   --smb-credentials ~/.smbcreds

  Inspect a session without decrypting anything:
      $SCRIPT inspect /mnt/backup/witchhammer-2026-05-07T123456Z

  Verify integrity:
      $SCRIPT verify /mnt/backup/witchhammer-2026-05-07T123456Z

  Reinstall apt + flatpak packages (preview first, then run for real):
      $SCRIPT packages /mnt/backup/witchhammer-2026-05-07T123456Z \\
              --include apt,flatpak
      $SCRIPT packages /mnt/backup/witchhammer-2026-05-07T123456Z \\
              --include apt,flatpak --execute

  Stage configs to a scratch dir (default; safe):
      $SCRIPT configs /mnt/backup/witchhammer-2026-05-07T123456Z \\
              --archives home --execute

  Apply directly to /etc and \$HOME (after reviewing the staged version):
      $SCRIPT configs /mnt/backup/witchhammer-2026-05-07T123456Z \\
              --archives home,etc --apply-in-place --execute
EOF
}

version() { printf '%s %s\n' "$SCRIPT" "$VERSION"; }

# ---------------------------------------------------------------
# argv parsing
# ---------------------------------------------------------------
SUBCMD=""

parse_args() {
    if (( $# == 0 )); then usage; exit 0; fi
    SUBCMD="$1"; shift || true
    case "$SUBCMD" in
        list|inspect|verify|packages|configs) ;;
        -h|--help)    usage; exit 0 ;;
        --version)    version; exit 0 ;;
        *)            die "unknown subcommand: $SUBCMD  (try --help)" ;;
    esac

    # Optional positional <session-dir> right after the subcommand
    if (( $# )) && [[ "$1" != -* ]]; then
        SESSION="$1"; shift
    fi

    while (( $# )); do
        case "$1" in
            --dest)              DEST="$2"; shift 2 ;;
            --dest=*)            DEST="${1#*=}"; shift ;;
            --dry-run)           DRY_RUN=1; shift ;;
            --execute)           DRY_RUN=0; shift ;;
            --smb-credentials)   SMB_CREDENTIALS="$2"; shift 2 ;;
            --smb-credentials=*) SMB_CREDENTIALS="${1#*=}"; shift ;;
            --include)           IFS=',' read -ra INCLUDE <<<"$2"; shift 2 ;;
            --include=*)         IFS=',' read -ra INCLUDE <<<"${1#*=}"; shift ;;
            --skip)              IFS=',' read -ra SKIP <<<"$2"; shift 2 ;;
            --skip=*)            IFS=',' read -ra SKIP <<<"${1#*=}"; shift ;;
            --archives)          IFS=',' read -ra ARCHIVES <<<"$2"; shift 2 ;;
            --archives=*)        IFS=',' read -ra ARCHIVES <<<"${1#*=}"; shift ;;
            --scratch)           SCRATCH="$2"; shift 2 ;;
            --scratch=*)         SCRATCH="${1#*=}"; shift ;;
            --apply-in-place)    APPLY_IN_PLACE=1; shift ;;
            --tui)               USE_TUI=yes; shift ;;
            --no-tui)            USE_TUI=no;  shift ;;
            -v|--verbose)        VERBOSE=1; shift ;;
            -h|--help)           usage; exit 0 ;;
            --version)           version; exit 0 ;;
            *)                   die "unknown argument: $1  (try --help)" ;;
        esac
    done
}

# ---------------------------------------------------------------
# helpers shared by subcommands
# ---------------------------------------------------------------
require_session() {
    [[ -n "$SESSION" ]] || die "missing <session-dir> argument"
    if [[ "$SESSION" =~ ^(smb|cifs|nfs|file):// ]]; then
        # Mount whatever filesystem the URL points to and rebase SESSION on it.
        # The URL must include the actual session subdirectory, e.g.
        # smb://nas/backups/witchhammer-2026-05-07T123456Z
        mount_remote "$SESSION"
        SESSION="$MOUNTED_DEST"
    fi
    [[ -d "$SESSION" ]] || die "session directory does not exist: $SESSION"
    [[ -f "$SESSION/manifest.json" ]] \
        || log_warn "$SESSION has no manifest.json — proceeding, but this may not be a scrolls session"
}

extract_archive_to() {
    # extract_archive_to <archive> <out_dir>
    # Streams the archive contents into <out_dir>. Auto-detects whether
    # the file has a .gpg layer (encrypted) or is a plain .tar.zst.
    local archive="$1" outdir="$2"
    [[ -f "$archive" ]] || die "archive not found: $archive"
    mkdir_p "$outdir"

    local encrypted=0
    [[ "$archive" == *.gpg ]] && encrypted=1

    if dry; then
        if (( encrypted )); then
            log_dry "gpg --decrypt $archive | zstd -d | tar --xattrs --acls -C $outdir -xf -"
        else
            log_dry "zstd -d <$archive | tar --xattrs --acls -C $outdir -xf -"
        fi
        return 0
    fi

    if (( encrypted )); then
        gpg --batch --quiet --decrypt "$archive" \
            | zstd -d -q \
            | tar --xattrs --acls --numeric-owner -C "$outdir" -xf -
    else
        zstd -d -q <"$archive" \
            | tar --xattrs --acls --numeric-owner -C "$outdir" -xf -
    fi
}

# Resolve <session>/configs/<name>.{tar.zst.gpg|tar.zst} → full path
# (preferring encrypted over plain when both exist for the same name).
resolve_archive_path() {
    local session="$1" name="$2"
    if   [[ -f "$session/configs/${name}.tar.zst.gpg" ]]; then
        printf '%s' "$session/configs/${name}.tar.zst.gpg"
    elif [[ -f "$session/configs/${name}.tar.zst" ]]; then
        printf '%s' "$session/configs/${name}.tar.zst"
    else
        return 1
    fi
}

# ---------------------------------------------------------------
# subcommand: list
# ---------------------------------------------------------------
cmd_list() {
    [[ -n "$DEST" ]] || die "list requires --dest"
    resolve_dest "$DEST"
    [[ -d "$DEST" ]] || die "destination not accessible: $DEST"

    log_info "sessions under: $DEST"
    printf '\n%-44s  %-9s  %s\n' "SESSION" "SIZE" "MANIFEST?"
    printf '%-44s  %-9s  %s\n'   "-------" "----" "---------"
    local d size sentinel
    while IFS= read -r d; do
        size="$(du -sh "$d" 2>/dev/null | awk '{print $1}')"
        sentinel="no"
        [[ -f "$d/manifest.json" ]] && sentinel="yes"
        printf '%-44s  %-9s  %s\n' "$(basename "$d")" "${size:-?}" "$sentinel"
    done < <(find "$DEST" -mindepth 1 -maxdepth 1 -type d | LC_ALL=C sort)
    printf '\n'
}

# ---------------------------------------------------------------
# subcommand: inspect
# ---------------------------------------------------------------
cmd_inspect() {
    require_session
    log_info "inspecting: $SESSION"

    if [[ -f "$SESSION/manifest.json" ]]; then
        printf '\n--- manifest.json ---\n'
        if have_cmd jq; then
            jq . "$SESSION/manifest.json"
        else
            cat "$SESSION/manifest.json"
        fi
    fi

    printf '\n--- contents ---\n'
    ( cd "$SESSION" && find . -maxdepth 4 -printf '%-60p  %s bytes\n' 2>/dev/null \
        | LC_ALL=C sort | head -n 200 )

    # Show package inventories (plain text by default)
    if [[ -d "$SESSION/packages" ]]; then
        printf '\n--- packages/ inventories present ---\n'
        ( cd "$SESSION/packages" && ls -1 )
    fi

    printf '\n'
    printf 'archives present:\n'
    ( cd "$SESSION/configs" 2>/dev/null && ls -1 ) || true
    printf '\n'
}

# ---------------------------------------------------------------
# subcommand: verify
# ---------------------------------------------------------------
cmd_verify() {
    require_session
    require_cmd sha256sum coreutils
    require_cmd gpg "gnupg or gnupg2"

    local sums="$SESSION/SHA256SUMS"
    local sig="$SESSION/SHA256SUMS.sig"
    [[ -f "$sums" ]] || die "no SHA256SUMS in $SESSION"

    log_info "checking sha256 sums..."
    if ( cd "$SESSION" && sha256sum --check --quiet "$sums" ); then
        log_ok "sha256sums OK"
    else
        die "sha256sum check failed"
    fi

    if [[ -f "$sig" ]]; then
        log_info "checking gpg signature on SHA256SUMS..."
        if gpg --verify "$sig" "$sums" 2>&1 | tee /dev/stderr | grep -qE 'Good signature'; then
            log_ok "gpg signature OK"
        else
            die "gpg signature verification failed"
        fi
    else
        log_warn "no SHA256SUMS.sig present (symmetric backup, or signing was skipped)"
    fi
}

# ---------------------------------------------------------------
# subcommand: packages
# ---------------------------------------------------------------
selected_for() {
    # selected_for <name>  → 0 if user wants this manager, 1 otherwise
    local name="$1" x
    if (( ${#INCLUDE[@]} )); then
        for x in "${INCLUDE[@]}"; do [[ "$x" == "$name" ]] && return 0; done
        return 1
    fi
    for x in "${SKIP[@]}"; do [[ "$x" == "$name" ]] && return 1; done
    return 0
}

cmd_packages() {
    require_session
    local pkgdir="$SESSION/packages"
    if [[ ! -d "$pkgdir" ]]; then
        # --encrypt-all backup: inventories live inside an archive (plain or .gpg).
        local enc
        if enc="$(resolve_archive_path "$SESSION" inventories)"; then
            log_info "extracting inventories archive to scratch dir ($enc)"
            local scratch
            scratch="$(mktemp -d -t scrolls-pkg.XXXXXX)"
            extract_archive_to "$enc" "$scratch"
            pkgdir="$scratch/packages"
        fi
    fi
    [[ -d "$pkgdir" ]] || die "no packages/ inventory in this session"

    log_info "replaying package inventories from: $pkgdir"
    log_info "mode: $(dry_label)"
    dry && log_warn "DRY RUN — pass --execute to actually install."

    # APT
    if selected_for apt && [[ -f "$pkgdir/apt-manual.txt" ]] && have_cmd apt; then
        log_info "[apt] installing $(wc -l <"$pkgdir/apt-manual.txt") manual packages"
        local pkgs
        pkgs="$(grep -v '^[[:space:]]*$' "$pkgdir/apt-manual.txt" | tr '\n' ' ')"
        # shellcheck disable=SC2086 # we want word splitting on the package list
        run sudo apt-get install -y --no-install-recommends $pkgs
    fi

    # DNF
    if selected_for dnf && [[ -f "$pkgdir/dnf-userinstalled.txt" ]] && have_cmd dnf; then
        log_info "[dnf] installing user-installed packages"
        local pkgs
        pkgs="$(grep -v '^[[:space:]]*$' "$pkgdir/dnf-userinstalled.txt" | tr '\n' ' ')"
        # shellcheck disable=SC2086
        run sudo dnf install -y $pkgs
    fi

    # Pacman
    if selected_for pacman && [[ -f "$pkgdir/pacman-explicit.txt" ]] && have_cmd pacman; then
        log_info "[pacman] installing explicit packages"
        local pkgs
        pkgs="$(grep -v '^[[:space:]]*$' "$pkgdir/pacman-explicit.txt" | tr '\n' ' ')"
        # shellcheck disable=SC2086
        run sudo pacman -S --needed --noconfirm $pkgs
    fi

    # Flatpak
    if selected_for flatpak && [[ -f "$pkgdir/flatpak.txt" ]] && have_cmd flatpak; then
        log_info "[flatpak] installing apps"
        # File format: application origin branch arch
        # We re-add remotes first if available.
        if [[ -f "$pkgdir/flatpak-remotes.txt" ]]; then
            while read -r remote url; do
                [[ -z "$remote" || "$remote" == Name ]] && continue
                run flatpak remote-add --if-not-exists "$remote" "$url"
            done <"$pkgdir/flatpak-remotes.txt"
        fi
        while read -r app origin branch _arch; do
            [[ -z "$app" || "$app" == Application ]] && continue
            run flatpak install -y --noninteractive "$origin" "$app//$branch"
        done <"$pkgdir/flatpak.txt"
    fi

    # Snap
    if selected_for snap && [[ -f "$pkgdir/snap.txt" ]] && have_cmd snap; then
        log_info "[snap] installing snaps"
        # Skip header line; first column is name.
        local name
        while read -r name _; do
            [[ -z "$name" || "$name" == Name ]] && continue
            run sudo snap install "$name"
        done <"$pkgdir/snap.txt"
    fi

    # pipx
    if selected_for pipx && [[ -f "$pkgdir/pipx.txt" ]] && have_cmd pipx; then
        log_info "[pipx] installing python apps"
        # Format from `pipx list --short`: "<package> <version>"
        local name _ver
        while read -r name _ver; do
            [[ -z "$name" ]] && continue
            run pipx install "$name"
        done <"$pkgdir/pipx.txt"
    fi

    # Cargo
    if selected_for cargo && [[ -f "$pkgdir/cargo.txt" ]] && have_cmd cargo; then
        log_info "[cargo] reinstalling cargo binaries"
        # Format: lines starting with package name + version, indented dependency
        # lines for the binaries. Pull only the top-level package names.
        local crate
        while read -r line; do
            [[ "$line" =~ ^[[:space:]] ]] && continue
            crate="$(awk '{print $1}' <<<"$line")"
            [[ -z "$crate" ]] && continue
            run cargo install "$crate"
        done <"$pkgdir/cargo.txt"
    fi

    # Go
    if selected_for go && [[ -f "$pkgdir/go.txt" ]] && have_cmd go; then
        log_info "[go] reinstalling go binaries"
        local mod
        while read -r mod; do
            [[ -z "$mod" ]] && continue
            run go install "$mod@latest"
        done <"$pkgdir/go.txt"
    fi

    log_ok "packages: done"
}

# ---------------------------------------------------------------
# subcommand: configs
# ---------------------------------------------------------------
default_archives() {
    # If --archives wasn't passed, pick whatever's present in configs/.
    # Handles both .tar.zst.gpg (encrypted) and .tar.zst (plain) archives,
    # deduping so a session with one mode doesn't list the same name twice.
    local d="$SESSION/configs" base name f
    [[ -d "$d" ]] || return 0
    local -A seen=()
    for f in "$d"/*.tar.zst.gpg "$d"/*.tar.zst; do
        [[ -f "$f" ]] || continue
        base="$(basename "$f")"
        name="${base%.tar.zst*}"
        [[ -n "${seen[$name]:-}" ]] && continue
        seen[$name]=1
        ARCHIVES+=("$name")
    done
}

apply_diff_summary() {
    # apply_diff_summary <staged_root> <name>
    # Print a small diff summary against the live filesystem so the user
    # can decide whether to --apply-in-place. Uses rsync --dry-run for the
    # heavy lifting (cheap, accurate, no temporary writes).
    local staged="$1" name="$2"
    local target=""
    case "$name" in
        etc)          target="/" ;;   # staged tree contains "etc/..."
        home)         target="/" ;;   # staged tree contains "home/<user>/..."
        custom)       target="/" ;;   # staged tree contains "usr/...", etc.
        inventories)  return 0 ;;     # plain-text inventories — no diff
    esac
    [[ -n "$target" ]] || return 0

    log_info "[$name] diff summary against $target (rsync --dry-run)"
    # --itemize-changes shows what would change
    rsync --archive --acls --xattrs --hard-links --numeric-ids \
          --dry-run --itemize-changes \
          "$staged/" "$target" 2>/dev/null \
        | head -n 50
    printf '   (showing first 50 changes; pass --apply-in-place to write them)\n'
}

cmd_configs() {
    require_session
    require_cmd gpg "gnupg or gnupg2"
    require_cmd zstd zstd
    require_cmd tar tar

    if (( ${#ARCHIVES[@]} == 0 )); then
        default_archives
    fi
    if (( ${#ARCHIVES[@]} == 0 )); then
        die "no archives found in $SESSION/configs/"
    fi

    if [[ -z "$SCRATCH" ]]; then
        local base="${XDG_RUNTIME_DIR:-/tmp}"
        SCRATCH="$base/scrolls-restore-$(date +%s)"
    fi
    mkdir_p "$SCRATCH"
    log_info "scratch dir: $SCRATCH"

    local name
    for name in "${ARCHIVES[@]}"; do
        local archive out="$SCRATCH/$name"
        if ! archive="$(resolve_archive_path "$SESSION" "$name")"; then
            log_warn "[$name] no archive (.tar.zst.gpg or .tar.zst) under $SESSION/configs/ — skipping"
            continue
        fi
        if [[ "$archive" == *.gpg ]]; then
            log_info "[$name] decrypt + extract → $out  (from $(basename "$archive"))"
        else
            log_info "[$name] extract → $out  (from $(basename "$archive"); unencrypted)"
        fi
        extract_archive_to "$archive" "$out"

        if (( APPLY_IN_PLACE )); then
            log_warn "[$name] --apply-in-place: rsync staging into /"
            local rsync_args=(
                --archive
                --acls
                --xattrs
                --hard-links
                --numeric-ids
            )
            [[ "$VERBOSE" == 1 ]] && rsync_args+=(--info=progress2 --verbose)
            run rsync "${rsync_args[@]}" "$out/" /
        else
            apply_diff_summary "$out" "$name"
        fi
    done

    if (( APPLY_IN_PLACE )); then
        log_ok "configs: applied in place"
    else
        log_ok "configs: staged at $SCRATCH (no live filesystem changes)"
        printf '\nReview the staged tree, then if it looks right run:\n'
        printf '  %s configs %s --archives %s --apply-in-place --execute\n\n' \
            "$SCRIPT" "$SESSION" "$(IFS=','; printf '%s' "${ARCHIVES[*]}")"
    fi
}

# ---------------------------------------------------------------
# main
# ---------------------------------------------------------------
main() {
    parse_args "$@"

    case "$SUBCMD" in
        list)     cmd_list ;;
        inspect)  cmd_inspect ;;
        verify)   cmd_verify ;;
        packages) cmd_packages ;;
        configs)  cmd_configs ;;
        *)        die "unhandled subcommand: $SUBCMD" ;;
    esac
}

main "$@"

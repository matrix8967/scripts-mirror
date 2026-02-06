#!/usr/bin/env bash
set -euo pipefail

# install_ctrld.sh
# - Usage: install_ctrld.sh [--version <v>] [--install] [--list] [--check] [--help]
# - Detects OS/arch, downloads release asset, verifies checksum (if present),
#   extracts ctrld from dist/<dir>/ctrld, and optionally installs to /usr/local/bin.

REPO="Control-D-Inc/ctrld"
INSTALL_PATH="/usr/local/bin/ctrld"
TMP_DIR="$(mktemp -d)"
ORIG_ARGS=("$@")

# Defaults
VERSION="latest"
INSTALL=false
LIST=false
CHECK=false
HELP=false

# Utilities
info(){ printf "\033[1;36m[INFO]\033[0m %s\n" "$*"; }
warn(){ printf "\033[1;33m[WARN]\033[0m %s\n" "$*"; }
err(){ printf "\033[1;31m[ERR]\033[0m %s\n" "$*"; exit 1; }

cleanup(){ rm -rf "$TMP_DIR"; }
trap cleanup EXIT

# ------------ Arg parsing (robust) ------------
while [[ $# -gt 0 ]]; do
  case "$1" in
    -v|--version)
      if [[ -z "${2:-}" || "${2:0:1}" == "-" ]]; then
        err "Value expected for $1"
      fi
      VERSION="${2#v}" # accept v1.2.3 or 1.2.3
      shift 2
      ;;
    --version=*)
      VERSION="${1#*=}"
      VERSION="${VERSION#v}"
      shift
      ;;
    -i|--install)
      INSTALL=true
      shift
      ;;
    --list)
      LIST=true
      shift
      ;;
    --check)
      CHECK=true
      shift
      ;;
    -h|--help)
      HELP=true
      shift
      ;;
    *)
      err "Unknown argument: $1"
      ;;
  esac
done

if $HELP; then
  cat <<EOF
Usage: $(basename "$0") [options]

Options:
  -v, --version <tag>    Specify release version (ex: 1.4.8 or v1.4.8). Default: latest
  -i, --install          Install to ${INSTALL_PATH} (requires root)
  --list                 List available release tags (most recent first)
  --check                Dry-run: print detected OS/arch and download URL, then exit
  -h, --help             Show this help message
EOF
  exit 0
fi

# --------------- Helpers ----------------
need_cmd(){ command -v "$1" >/dev/null 2>&1 || err "Required tool not found: $1"; }

# jq required for more reliable API parsing; curl must exist
need_cmd curl
need_cmd jq

# For checksum: try sha256sum then shasum -a 256
calc_sha256(){
  local file="$1"
  if command -v sha256sum >/dev/null 2>&1; then
    sha256sum "$file" | awk '{print $1}'
  elif command -v shasum >/dev/null 2>&1; then
    shasum -a 256 "$file" | awk '{print $1}'
  else
    err "No SHA256 tool found (sha256sum or shasum required)"
  fi
}

# --------------- List releases ---------------
if $LIST; then
  curl -s "https://api.github.com/repos/${REPO}/releases" \
    | jq -r '.[].tag_name' \
    | sed 's/^v//' \
    | sort -Vr
  exit 0
fi

# --------------- Detect OS + Arch ---------------
os_raw="$(uname -s | tr '[:upper:]' '[:lower:]')"
arch_raw="$(uname -m)"

case "$os_raw" in
  linux) OS="linux" ;;
  darwin) OS="darwin" ;;
  freebsd) OS="freebsd" ;;
  *) err "Unsupported OS: $os_raw" ;;
esac

case "$arch_raw" in
  x86_64|amd64) ARCH="amd64" ;;
  aarch64|arm64) ARCH="arm64" ;;
  armv7*|armhf) ARCH="armv7" ;;
  i386|i686) ARCH="386" ;;
  mips64el) ARCH="mips64le" ;;
  mips64) ARCH="mips64" ;;
  mipsel) ARCH="mipsle" ;;
  mips) ARCH="mips" ;;
  ppc64le) ARCH="ppc64le" ;;
  ppc64) ARCH="ppc64" ;;
  *) err "Unsupported architecture: $arch_raw" ;;
esac

info "OS: $OS"
info "Arch: $ARCH"
info "Version: ${VERSION}"

# --------------- Determine release API URL ---------------
if [[ "$VERSION" == "latest" ]]; then
  api_url="https://api.github.com/repos/${REPO}/releases/latest"
  ver_label="latest"
else
  # allow user to pass with or without leading v
  ver_trimmed="${VERSION#v}"
  api_url="https://api.github.com/repos/${REPO}/releases/tags/v${ver_trimmed}"
  ver_label="v${ver_trimmed}"
fi

# Query release JSON
info "Querying GitHub release info..."
release_json="$(curl -fsSL "$api_url")" || err "Failed to query release info: $api_url"

# --------------- Find matching asset ---------------
asset_url=$(printf '%s' "$release_json" \
  | jq -r --arg os "$OS" --arg arch "$ARCH" '
      .assets[]? | select(
        (.name | ascii_downcase | test($os)) and
        (.name | ascii_downcase | test($arch))
      ) | .browser_download_url' \
  | head -n1
)

if [[ -z "$asset_url" || "$asset_url" == "null" ]]; then
  err "No matching asset found for ${OS}-${ARCH} in release ${ver_label}"
fi

# Find any checksums asset (optional)
checksums_url=$(printf '%s' "$release_json" \
  | jq -r '
      .assets[]? | select((.name|ascii_downcase) | test("checksums|sha256")) | .browser_download_url' \
  | head -n1 || true
)

if $CHECK; then
  echo "DRY RUN:"
  echo "  OS:    $OS"
  echo "  Arch:  $ARCH"
  echo "  Ver:   $ver_label"
  echo "  URL:   $asset_url"
  [[ -n "$checksums_url" ]] && echo "  Checksums: $checksums_url"
  exit 0
fi

info "Asset URL: $asset_url"
[ -n "$checksums_url" ] && info "Checksums URL: $checksums_url"

# --------------- Download ---------------
archive_name="${asset_url##*/}"
curl -fL -o "$TMP_DIR/$archive_name" "$asset_url" || err "Download failed: $asset_url"

# Download checksums if present
if [[ -n "$checksums_url" && "$checksums_url" != "null" ]]; then
  curl -fL -o "$TMP_DIR/checksums.txt" "$checksums_url" || warn "Failed to download checksums; continuing without verification"
fi

# --------------- Verify checksum (if we have checksums.txt) ---------------
if [[ -f "$TMP_DIR/checksums.txt" ]]; then
  expected=$(grep -i "$archive_name" "$TMP_DIR/checksums.txt" | awk '{print $1}' | tr '[:upper:]' '[:lower:]' | head -n1 || true)
  if [[ -z "$expected" ]]; then
    warn "Checksums file present but no entry for $archive_name; skipping verification"
  else
    actual=$(calc_sha256 "$TMP_DIR/$archive_name")
    actual="${actual,,}"
    if [[ "$expected" != "$actual" ]]; then
      err "Checksum mismatch! expected:$expected actual:$actual"
    fi
    info "Checksum OK"
  fi
else
  warn "No checksums file — skipping checksum verification"
fi

# --------------- Extract ctrld binary (accounting for dist/<dir>/ctrld) ---------------
info "Extracting ctrld binary from archive..."
cd "$TMP_DIR"
case "$archive_name" in
  *.tar.gz|*.tgz)
    # Use --strip-components=2 to remove dist/<dir>/ prefix and extract only the ctrld binary
    # But older tar implementations may not allow pattern after -xzf; use a safe two-step:
    # 1) list to confirm path then extract the specific entry with --strip-components
    member=$(tar -tzf "$archive_name" | grep -E '(^|/)dist/[^/]+/ctrld$' | head -n1 || true)
    if [[ -n "$member" ]]; then
      tar --strip-components=2 -xzf "$archive_name" -C "$TMP_DIR" "$member"
    else
      # fallback: extract everything then find binary
      tar -xzf "$archive_name" -C "$TMP_DIR"
      member=$(find . -type f -name ctrld | head -n1 || true)
      [[ -n "$member" ]] || err "ctrld binary not found after extraction"
      mv "$member" "$TMP_DIR/ctrld"
    fi
    ;;
  *.zip)
    need_cmd unzip
    unzip -q "$archive_name" -d "$TMP_DIR/extract"
    # locate nested ctrld under dist/*/ctrld
    member=$(find "$TMP_DIR/extract" -type f -path '*/dist/*/ctrld' -print -quit || true)
    if [[ -n "$member" ]]; then
      mv "$member" "$TMP_DIR/ctrld"
    else
      member=$(find "$TMP_DIR/extract" -type f -name ctrld -print -quit || true)
      [[ -n "$member" ]] || err "ctrld binary not found in zip"
      mv "$member" "$TMP_DIR/ctrld"
    fi
    ;;
  *)
    err "Unknown archive format: $archive_name"
    ;;
esac

if [[ ! -f "$TMP_DIR/ctrld" ]]; then
  err "ctrld binary not found after extraction"
fi

chmod +x "$TMP_DIR/ctrld"
info "Binary extracted: $TMP_DIR/ctrld"

# --------------- Install (optional) ---------------
if $INSTALL; then
  # If not root, re-run with sudo and same original args (to ensure permissions)
  if [[ "$(id -u)" -ne 0 ]]; then
    info "Elevating to install with sudo..."
    exec sudo "${ORIG_ARGS[@]}" # re-exec with original args (script invoked under sudo)
  fi

  info "Installing to ${INSTALL_PATH} ..."
  install -m 0755 "$TMP_DIR/ctrld" "$INSTALL_PATH"
  info "Installed: ${INSTALL_PATH}"
  # try show version if cli supports --version
  if command -v "$INSTALL_PATH" >/dev/null 2>&1; then
    "$INSTALL_PATH" --version 2>/dev/null || true
  fi
else
  info "Install skipped. Binary available at: $TMP_DIR/ctrld"
  printf "To manually install: sudo install -m 0755 %s %s\n" "$TMP_DIR/ctrld" "$INSTALL_PATH"
fi

# finished
exit 0

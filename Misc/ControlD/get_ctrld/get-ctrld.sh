#!/usr/bin/env bash
set -euo pipefail

# get-ctrld.sh
# Enhanced installer for ctrld with platform detection and guided setup
# Usage: get-ctrld.sh [--version <v>] [--install] [--list] [--check] [--platform <type>] [--interactive] [--help]

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
INTERACTIVE=false
PLATFORM_OVERRIDE=""

# Platform detection results
PLATFORM_TYPE=""
PLATFORM_NAME=""
INSTALL_RECOMMENDATION=""
CONFIG_PATH=""
SERVICE_TYPE=""

# Utilities
info(){ printf "\033[1;36m[INFO]\033[0m %s\n" "$*"; }
warn(){ printf "\033[1;33m[WARN]\033[0m %s\n" "$*"; }
err(){ printf "\033[1;31m[ERR]\033[0m %s\n" "$*"; exit 1; }
success(){ printf "\033[1;32m[SUCCESS]\033[0m %s\n" "$*"; }

cleanup(){ rm -rf "$TMP_DIR"; }
trap cleanup EXIT

# --------------- Platform Detection ---------------
detect_platform() {
  info "Detecting platform..."

  # ASUSWRT-Merlin
  if [[ -d "/jffs/configs" ]] && [[ -f "/usr/sbin/amtm" || -f "/jffs/scripts/services-start" ]]; then
    PLATFORM_TYPE="asuswrt-merlin"
    PLATFORM_NAME="ASUSWRT-Merlin"
    INSTALL_RECOMMENDATION="/opt/bin/ctrld"
    CONFIG_PATH="/opt/etc/controld"
    SERVICE_TYPE="entware"
    return
  fi

  # FreshTomato
  if [[ -d "/jffs/controld" ]] || grep -qi "tomato" /proc/version 2>/dev/null; then
    PLATFORM_TYPE="freshtomato"
    PLATFORM_NAME="FreshTomato"
    INSTALL_RECOMMENDATION="/jffs/controld/ctrld"
    CONFIG_PATH="/jffs/controld"
    SERVICE_TYPE="init-script"
    return
  fi

  # OpenWRT
  if [[ -f "/etc/openwrt_release" ]]; then
    PLATFORM_TYPE="openwrt"
    PLATFORM_NAME="OpenWRT"
    INSTALL_RECOMMENDATION="/usr/bin/ctrld"
    CONFIG_PATH="/etc/config"
    SERVICE_TYPE="procd"
    return
  fi

  # EdgeOS/VyOS
  if [[ -d "/opt/vyatta" ]] || [[ -f "/etc/version" ]] && grep -qi "vyos\|edgeos" /etc/version 2>/dev/null; then
    PLATFORM_TYPE="edgeos"
    PLATFORM_NAME="EdgeOS/VyOS"
    INSTALL_RECOMMENDATION="/config/scripts/ctrld"
    CONFIG_PATH="/config/controld"
    SERVICE_TYPE="systemd"
    return
  fi

  # pfSense/OPNsense
  if [[ -f "/etc/platform" ]] && grep -qi "pfsense\|opnsense" /etc/platform 2>/dev/null; then
    PLATFORM_TYPE="pfsense"
    PLATFORM_NAME="pfSense/OPNsense"
    INSTALL_RECOMMENDATION="/usr/local/bin/ctrld"
    CONFIG_PATH="/usr/local/etc/controld"
    SERVICE_TYPE="rc.d"
    return
  fi

  # MikroTik RouterOS (if running in container/metarouter)
  if [[ -f "/nova/etc/devel-login" ]]; then
    PLATFORM_TYPE="mikrotik"
    PLATFORM_NAME="MikroTik RouterOS"
    INSTALL_RECOMMENDATION="/rw/disk/ctrld"
    CONFIG_PATH="/rw/disk/controld"
    SERVICE_TYPE="manual"
    return
  fi

  # Standard Linux with systemd
  if command -v systemctl >/dev/null 2>&1 && systemctl --version >/dev/null 2>&1; then
    PLATFORM_TYPE="linux-systemd"
    PLATFORM_NAME="Linux (systemd)"
    INSTALL_RECOMMENDATION="/usr/local/bin/ctrld"
    CONFIG_PATH="/etc/controld"
    SERVICE_TYPE="systemd"

    # Detect specific distro for better guidance
    if [[ -f "/etc/os-release" ]]; then
      . /etc/os-release
      PLATFORM_NAME="$NAME (systemd)"
    fi
    return
  fi

  # Standard Linux without systemd
  if [[ "$OS" == "linux" ]]; then
    PLATFORM_TYPE="linux-generic"
    PLATFORM_NAME="Linux (generic)"
    INSTALL_RECOMMENDATION="/usr/local/bin/ctrld"
    CONFIG_PATH="/etc/controld"
    SERVICE_TYPE="init.d"
    return
  fi

  # macOS
  if [[ "$OS" == "darwin" ]]; then
    PLATFORM_TYPE="macos"
    PLATFORM_NAME="macOS"
    INSTALL_RECOMMENDATION="/usr/local/bin/ctrld"
    CONFIG_PATH="$HOME/.controld"
    SERVICE_TYPE="launchd"
    return
  fi

  # FreeBSD
  if [[ "$OS" == "freebsd" ]]; then
    PLATFORM_TYPE="freebsd"
    PLATFORM_NAME="FreeBSD"
    INSTALL_RECOMMENDATION="/usr/local/bin/ctrld"
    CONFIG_PATH="/usr/local/etc/controld"
    SERVICE_TYPE="rc.d"
    return
  fi

  # Fallback
  PLATFORM_TYPE="unknown"
  PLATFORM_NAME="Unknown Platform"
  INSTALL_RECOMMENDATION="/usr/local/bin/ctrld"
  CONFIG_PATH="/etc/controld"
  SERVICE_TYPE="manual"
}

# --------------- Post-Install Guidance ---------------
show_platform_guidance() {
  local binary_path="$1"

  echo ""
  success "ctrld binary ready!"
  echo ""
  info "Platform detected: ${PLATFORM_NAME}"
  echo ""

  case "$PLATFORM_TYPE" in
    asuswrt-merlin)
      cat <<EOF
┌─────────────────────────────────────────────────────────────────┐
│ ASUSWRT-Merlin Installation Guide                              │
└─────────────────────────────────────────────────────────────────┘

Recommended installation path: /opt/bin/ctrld
Config directory: /opt/etc/controld

Next steps:
  1. Install Entware (if not already installed):
     Run: amtm -> Entware

  2. Copy ctrld to persistent storage:
     cp ${binary_path} /opt/bin/ctrld
     chmod +x /opt/bin/ctrld

  3. Create config directory:
     mkdir -p /opt/etc/controld

  4. Run initial setup:
     /opt/bin/ctrld start

  5. Add to services-start for persistence:
     echo "/opt/bin/ctrld start" >> /jffs/scripts/services-start
     chmod +x /jffs/scripts/services-start

For more info: https://docs.controld.com/docs/routers-asuswrt-merlin
EOF
      ;;

    freshtomato)
      cat <<EOF
┌─────────────────────────────────────────────────────────────────┐
│ FreshTomato Installation Guide                                 │
└─────────────────────────────────────────────────────────────────┘

Recommended installation path: /jffs/controld/ctrld
Config directory: /jffs/controld

Next steps:
  1. Create persistent directory:
     mkdir -p /jffs/controld

  2. Copy binary:
     cp ${binary_path} /jffs/controld/ctrld
     chmod +x /jffs/controld/ctrld

  3. Run initial setup:
     /jffs/controld/ctrld start

  4. Add init script in Admin -> Scripts -> Init:
     #!/bin/sh
     /jffs/controld/ctrld start

For more info: https://docs.controld.com/docs/routers-freshtomato
EOF
      ;;

    openwrt)
      cat <<'EOF'
┌─────────────────────────────────────────────────────────────────┐
│ OpenWRT Installation Guide                                      │
└─────────────────────────────────────────────────────────────────┘

Recommended installation path: /usr/bin/ctrld
Config directory: /etc/config

Next steps:
  1. Copy binary:
     cp ${binary_path} /usr/bin/ctrld
     chmod +x /usr/bin/ctrld

  2. Create procd init script at /etc/init.d/ctrld:

     #!/bin/sh /etc/rc.common
     START=99
     STOP=10

     USE_PROCD=1
     PROG=/usr/bin/ctrld

     start_service() {
         procd_open_instance
         procd_set_param command $PROG run
         procd_set_param respawn
         procd_close_instance
     }

  3. Enable and start service:
     chmod +x /etc/init.d/ctrld
     /etc/init.d/ctrld enable
     /etc/init.d/ctrld start

For more info: https://docs.controld.com/docs/routers-openwrt
EOF
      ;;

    edgeos)
      cat <<EOF
┌─────────────────────────────────────────────────────────────────┐
│ EdgeOS/VyOS Installation Guide                                  │
└─────────────────────────────────────────────────────────────────┘

Recommended installation path: /config/scripts/ctrld
Config directory: /config/controld

Next steps:
  1. Copy to persistent config:
     sudo cp ${binary_path} /config/scripts/ctrld
     sudo chmod +x /config/scripts/ctrld

  2. Create config directory:
     sudo mkdir -p /config/controld

  3. Create systemd service at /etc/systemd/system/ctrld.service:

     [Unit]
     Description=Control D DNS Proxy
     After=network.target

     [Service]
     Type=simple
     ExecStart=/config/scripts/ctrld run
     Restart=on-failure

     [Install]
     WantedBy=multi-user.target

  4. Enable and start:
     sudo systemctl daemon-reload
     sudo systemctl enable ctrld
     sudo systemctl start ctrld

For more info: https://docs.controld.com/docs/routers-edgeos
EOF
      ;;

    linux-systemd)
      cat <<EOF
┌─────────────────────────────────────────────────────────────────┐
│ Linux (systemd) Installation Guide                             │
└─────────────────────────────────────────────────────────────────┘

Recommended installation path: /usr/local/bin/ctrld
Config directory: /etc/controld

Next steps:
  1. Install binary (if not already done with --install):
     sudo install -m 0755 ${binary_path} /usr/local/bin/ctrld

  2. Create config directory:
     sudo mkdir -p /etc/controld

  3. Run initial setup:
     sudo ctrld start

  4. (Optional) Create systemd service at /etc/systemd/system/ctrld.service:

     [Unit]
     Description=Control D DNS Proxy
     After=network-online.target
     Wants=network-online.target

     [Service]
     Type=simple
     ExecStart=/usr/local/bin/ctrld run
     Restart=on-failure
     RestartSec=5

     [Install]
     WantedBy=multi-user.target

  5. Enable and start service:
     sudo systemctl daemon-reload
     sudo systemctl enable ctrld
     sudo systemctl start ctrld
     sudo systemctl status ctrld

For more info: https://docs.controld.com/docs/installation-linux
EOF
      ;;

    macos)
      cat <<EOF
┌─────────────────────────────────────────────────────────────────┐
│ macOS Installation Guide                                        │
└─────────────────────────────────────────────────────────────────┘

Recommended installation path: /usr/local/bin/ctrld
Config directory: ~/.controld

Next steps:
  1. Install binary (if not already done with --install):
     sudo install -m 0755 ${binary_path} /usr/local/bin/ctrld

  2. Run initial setup:
     ctrld start

  3. (Optional) Create LaunchDaemon at ~/Library/LaunchAgents/com.controld.ctrld.plist:

     <?xml version="1.0" encoding="UTF-8"?>
     <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
     <plist version="1.0">
     <dict>
         <key>Label</key>
         <string>com.controld.ctrld</string>
         <key>ProgramArguments</key>
         <array>
             <string>/usr/local/bin/ctrld</string>
             <string>run</string>
         </array>
         <key>RunAtLoad</key>
         <true/>
         <key>KeepAlive</key>
         <true/>
     </dict>
     </plist>

  4. Load the service:
     launchctl load ~/Library/LaunchAgents/com.controld.ctrld.plist

For more info: https://docs.controld.com/docs/installation-macos
EOF
      ;;

    *)
      cat <<EOF
┌─────────────────────────────────────────────────────────────────┐
│ Generic Installation Guide                                      │
└─────────────────────────────────────────────────────────────────┘

Platform not automatically detected. Manual installation required.

Binary location: ${binary_path}

Basic steps:
  1. Copy binary to desired location:
     sudo cp ${binary_path} ${INSTALL_RECOMMENDATION}
     sudo chmod +x ${INSTALL_RECOMMENDATION}

  2. Run ctrld to configure:
     ${INSTALL_RECOMMENDATION} start

  3. Set up auto-start using your platform's init system

For documentation: https://docs.controld.com/docs
EOF
      ;;
  esac

  echo ""
  info "Test DNS resolution: curl -s https://verify.controld.com/txt"
  echo ""
}

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
    --interactive)
      INTERACTIVE=true
      shift
      ;;
    --platform)
      if [[ -z "${2:-}" || "${2:0:1}" == "-" ]]; then
        err "Value expected for $1"
      fi
      PLATFORM_OVERRIDE="$2"
      shift 2
      ;;
    --platform=*)
      PLATFORM_OVERRIDE="${1#*=}"
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

Enhanced ctrld installer with platform detection and guided setup.

Options:
  -v, --version <tag>     Specify release version (ex: 1.4.8 or v1.4.8). Default: latest
  -i, --install           Install to recommended path for detected platform
  --list                  List available release tags (most recent first)
  --check                 Dry-run: print detected OS/arch/platform and download URL
  --interactive           Interactive mode with prompts and confirmations
  --platform <type>       Override platform detection (for remote installs)
                          Types: asuswrt-merlin, freshtomato, openwrt, edgeos,
                                 pfsense, linux-systemd, macos, freebsd
  -h, --help              Show this help message

Examples:
  $(basename "$0")                          # Download latest for current platform
  $(basename "$0") --version 1.4.8 --install  # Install specific version
  $(basename "$0") --platform openwrt       # Download for OpenWRT (override detection)
  $(basename "$0") --check                  # Dry-run to see what would be downloaded

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

# Detect platform (unless overridden)
if [[ -n "$PLATFORM_OVERRIDE" ]]; then
  PLATFORM_TYPE="$PLATFORM_OVERRIDE"
  info "Platform override: $PLATFORM_TYPE"
else
  detect_platform
fi

info "OS: $OS"
info "Arch: $ARCH"
if [[ -n "$PLATFORM_NAME" ]]; then
  info "Platform: $PLATFORM_NAME"
fi
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
  echo "  OS:         $OS"
  echo "  Arch:       $ARCH"
  echo "  Platform:   $PLATFORM_NAME"
  echo "  Ver:        $ver_label"
  echo "  URL:        $asset_url"
  [[ -n "$checksums_url" ]] && echo "  Checksums:  $checksums_url"
  [[ -n "$INSTALL_RECOMMENDATION" ]] && echo "  Install to: $INSTALL_RECOMMENDATION"
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
  # Use platform-specific path if detected
  if [[ -n "$INSTALL_RECOMMENDATION" && "$PLATFORM_TYPE" != "unknown" ]]; then
    INSTALL_PATH="$INSTALL_RECOMMENDATION"
  fi

  # Create parent directory if needed
  install_dir="$(dirname "$INSTALL_PATH")"
  if [[ ! -d "$install_dir" ]]; then
    info "Creating directory: $install_dir"
    mkdir -p "$install_dir" 2>/dev/null || sudo mkdir -p "$install_dir"
  fi

  # If not root and target needs root, re-run with sudo
  if [[ "$(id -u)" -ne 0 ]] && [[ ! -w "$install_dir" ]]; then
    info "Elevating to install with sudo..."
    exec sudo bash "$0" "${ORIG_ARGS[@]}"
  fi

  info "Installing to ${INSTALL_PATH} ..."
  install -m 0755 "$TMP_DIR/ctrld" "$INSTALL_PATH"
  success "Installed: ${INSTALL_PATH}"

  # Try show version
  if command -v "$INSTALL_PATH" >/dev/null 2>&1; then
    "$INSTALL_PATH" --version 2>/dev/null || true
  fi

  # Show platform-specific guidance
  show_platform_guidance "$INSTALL_PATH"
else
  info "Install skipped. Binary available at: $TMP_DIR/ctrld"

  # Show platform-specific guidance
  show_platform_guidance "$TMP_DIR/ctrld"
fi

# finished
exit 0

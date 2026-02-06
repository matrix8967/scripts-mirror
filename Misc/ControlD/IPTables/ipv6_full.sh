#!/usr/bin/env bash
#
# ipv6-test-harness.sh
# Minimal, safe IPv6 test harness for ctrld QA
#
# Features:
#   - Verifies IPv6 connectivity
#   - Works with both ip6tables (legacy) and nftables (modern)
#   - Saves and restores firewall rules automatically
#   - Runs local (::1, link-local) and remote (global) IPv6 tests
#
# Usage: sudo ./ipv6-test-harness.sh
#

set -euo pipefail

BACKUP_FILE="/tmp/ipv6-fw-backup.$$.rules"
FW_MODE=""

restore_firewall() {
    echo "[*] Restoring previous IPv6 firewall rules..."
    if [[ "$FW_MODE" == "iptables" && -f "$BACKUP_FILE" ]]; then
        ip6tables-restore < "$BACKUP_FILE" || echo "[-] Failed to restore ip6tables rules"
        rm -f "$BACKUP_FILE"
    elif [[ "$FW_MODE" == "nftables" && -f "$BACKUP_FILE" ]]; then
        nft -f "$BACKUP_FILE" || echo "[-] Failed to restore nftables rules"
        rm -f "$BACKUP_FILE"
    else
        echo "[-] No firewall backup found to restore"
    fi
    echo "[+] Firewall restore complete."
}

# Ensure firewall is restored even on exit or Ctrl+C
trap restore_firewall EXIT INT TERM

echo "=== IPv6 Test Harness for ctrld ==="

# ---- Detect firewall mode ----
if command -v ip6tables >/dev/null 2>&1; then
    FW_MODE="iptables"
    echo "[*] Using ip6tables mode"
elif command -v nft >/dev/null 2>&1; then
    FW_MODE="nftables"
    echo "[*] Using nftables mode"
else
    echo "[-] Neither ip6tables nor nftables found. Cannot continue."
    exit 1
fi

# ---- Save firewall rules ----
if [[ "$FW_MODE" == "iptables" ]]; then
    echo "[*] Saving current ip6tables rules..."
    ip6tables-save > "$BACKUP_FILE"
elif [[ "$FW_MODE" == "nftables" ]]; then
    echo "[*] Saving current nftables rules..."
    nft list ruleset > "$BACKUP_FILE"
fi

# ---- Verify current IPv6 addresses ----
echo "[*] Checking IPv6 addresses..."
ip -6 addr show

# ---- Apply safe IPv6 firewall rules ----
if [[ "$FW_MODE" == "iptables" ]]; then
    echo "[*] Applying default-deny IPv6 firewall (ip6tables)..."
    ip6tables -F
    ip6tables -P INPUT DROP
    ip6tables -P FORWARD DROP
    ip6tables -P OUTPUT ACCEPT
    ip6tables -A INPUT -i lo -j ACCEPT
    ip6tables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
    echo "[+] Temporary ip6tables rules applied:"
    ip6tables -L -v
elif [[ "$FW_MODE" == "nftables" ]]; then
    echo "[*] Applying default-deny IPv6 firewall (nftables)..."
    nft flush ruleset
    nft add table inet filter
    nft add chain inet filter input { type filter hook input priority 0 \; policy drop \; }
    nft add chain inet filter forward { type filter hook forward priority 0 \; policy drop \; }
    nft add chain inet filter output { type filter hook output priority 0 \; policy accept \; }
    nft add rule inet filter input iif lo accept
    nft add rule inet filter input ct state established,related accept
    echo "[+] Temporary nftables rules applied:"
    nft list ruleset
fi

# ---- Local tests (loopback + link-local) ----
echo "[*] Testing ctrld on IPv6 loopback (::1)..."
dig @::1 verify.controld.com AAAA +short || echo "[-] Loopback dig failed"

iface=$(ip -o -6 addr show | awk '/fe80/ {print $2; exit}')
if [ -n "${iface:-}" ]; then
    echo "[*] Testing ctrld on IPv6 link-local (fe80::1%$iface)..."
    dig @"fe80::1%$iface" verify.controld.com AAAA +short || echo "[-] Link-local dig failed"
else
    echo "[-] No link-local interface detected"
fi

# ---- Remote connectivity tests ----
echo "[*] Checking global IPv6 connectivity..."
if ping6 -c2 google.com >/dev/null 2>&1; then
    echo "[+] IPv6 connectivity is working"
    curl -6 -s https://ifconfig.co || echo "[-] curl over IPv6 failed"
    dig AAAA verify.controld.com +short
else
    echo "[-] No IPv6 Internet connectivity detected"
fi

echo "=== Test Harness Complete ==="

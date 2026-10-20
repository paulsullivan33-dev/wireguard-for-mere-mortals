#!/bin/sh
# lab.sh — the one-machine lab from "WireGuard for Mere Mortals".
#
# Builds two WireGuard interfaces on one Linux machine — wg-hub
# (10.99.0.1, listening on UDP 51820) and wg-spoke (10.99.0.2,
# listening on 51821) — with the spoke's peer endpoint pointing
# at the hub over loopback. Everything the guide's first-tunnel
# chapter does by hand, in one script.
#
#   sudo ./lab.sh up     generate keys (once), build the lab
#   sudo ./lab.sh down   delete both interfaces (keys are kept)
#
# Keys and configs live in $WG_LAB_DIR (default
# /root/wg-mere-mortals-lab), created owner-only. The keys are
# throwaway lab keys; the directory is yours to delete.
#
# Needs: root, iproute2, wireguard-tools, and either the
# WireGuard kernel module or wireguard-go (the script falls
# back automatically, as wg-quick does). On a machine whose
# network refuses UDP outright — some sandboxes do — the
# interfaces will come up and the handshake will not complete;
# the guide's troubleshooting chapter shows exactly that state,
# captured from a machine like that.

set -eu

WORKDIR="${WG_LAB_DIR:-/root/wg-mere-mortals-lab}"
HUB_ADDR=10.99.0.1
SPOKE_ADDR=10.99.0.2
HUB_PORT=51820
SPOKE_PORT=51821

die() { echo "lab.sh: $*" >&2; exit 1; }

[ "$(id -u)" = 0 ] || die "run as root (sudo ./lab.sh ...)"
command -v wg >/dev/null || die "wg not found — install wireguard-tools"

make_iface() {
    # $1 = interface name. Kernel first, userspace fallback.
    if ip link add "$1" type wireguard 2>/dev/null; then
        return 0
    fi
    if command -v wireguard-go >/dev/null; then
        wireguard-go "$1" >/dev/null 2>&1
        return 0
    fi
    die "cannot create $1: no kernel WireGuard and no wireguard-go"
}

up() {
    umask 077
    mkdir -p "$WORKDIR"
    cd "$WORKDIR"
    if [ ! -f hub.key ]; then
        wg genkey > hub.key
        wg genkey > spoke.key
        wg pubkey < hub.key > hub.pub
        wg pubkey < spoke.key > spoke.pub
        wg genpsk > lab.psk
        echo "generated fresh lab keys in $WORKDIR"
    fi
    HUBKEY=$(cat hub.key); SPOKEKEY=$(cat spoke.key)
    HUBPUB=$(cat hub.pub); SPOKEPUB=$(cat spoke.pub); PSK=$(cat lab.psk)
    cat > hub.setconf <<EOF
[Interface]
PrivateKey = $HUBKEY
ListenPort = $HUB_PORT

[Peer]
PublicKey = $SPOKEPUB
PresharedKey = $PSK
AllowedIPs = $SPOKE_ADDR/32
EOF
    cat > spoke.setconf <<EOF
[Interface]
PrivateKey = $SPOKEKEY
ListenPort = $SPOKE_PORT

[Peer]
PublicKey = $HUBPUB
PresharedKey = $PSK
Endpoint = 127.0.0.1:$HUB_PORT
AllowedIPs = $HUB_ADDR/32
EOF
    ip link show wg-hub   >/dev/null 2>&1 || make_iface wg-hub
    ip link show wg-spoke >/dev/null 2>&1 || make_iface wg-spoke
    wg setconf wg-hub hub.setconf
    wg setconf wg-spoke spoke.setconf
    ip address add $HUB_ADDR/32 dev wg-hub 2>/dev/null || true
    ip address add $SPOKE_ADDR/32 dev wg-spoke 2>/dev/null || true
    ip link set wg-hub up
    ip link set wg-spoke up
    ip route replace $HUB_ADDR/32 dev wg-spoke
    ip route replace $SPOKE_ADDR/32 dev wg-hub
    echo
    echo "lab is up. The state the guide starts from:"
    echo
    wg show wg-hub
    wg show wg-spoke
    echo "On an ordinary machine: ping $HUB_ADDR and ping $SPOKE_ADDR"
    echo "answer, and 'wg show' gains a 'latest handshake' line."
    echo "Take the lab down with: $0 down"
}

down() {
    ip link del wg-hub 2>/dev/null || true
    ip link del wg-spoke 2>/dev/null || true
    echo "lab interfaces deleted. Keys kept in $WORKDIR (delete it to remove them)."
}

case "${1:-}" in
    up) up ;;
    down) down ;;
    *) echo "usage: $0 up|down" >&2; exit 2 ;;
esac

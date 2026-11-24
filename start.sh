#!/usr/bin/env bash

set -euo pipefail

################################################################################
# Configuration
################################################################################
# Set this to the MAC address of the wireless card you want to operate on
TARGET_MAC="ff:ff:ff:ff:ff:ff"

# Find the network interface name by MAC address
IFACE=$(ip -o link show | awk -v mac="$TARGET_MAC" '$0 ~ mac {print $2}' | cut -d: -f1)

if [ -z "$IFACE" ]; then
    echo "Interface with MAC $TARGET_MAC not found"
    exit 1
fi

# Find the corresponding phy name by interface name
# /sys/class/net/<iface>/phy80211/name contains the phy name
PHY=$(cat /sys/class/net/"$IFACE"/phy80211/name 2>/dev/null)

NETNS="printer"

WIFI_IF="printer0"

IP="192.168.50.1"
PREFIX="24"

ROOT="/opt/wifi-printer"
CFG="$ROOT/config"

PIDS=()

################################################################################
# Cleanup
################################################################################

cleanup()
{
    echo "[printer] cleanup"

    for pid in "${PIDS[@]:-}"; do
        kill "$pid" 2>/dev/null || true
    done

    sleep 2

    ip netns delete "$NETNS" 2>/dev/null || true

    rm -f /etc/avahi/services/airprint.service
}

trap cleanup EXIT INT TERM


################################################################################
# Remove stale state
################################################################################

echo "[printer] starting"

if ip netns list | grep -q "^$NETNS"; then
    echo "[printer] removing old namespace"
    ip netns delete "$NETNS"
fi


################################################################################
# Create namespace
################################################################################

echo "[printer] creating namespace"

ip netns add "$NETNS"


################################################################################
# Move WiFi PHY
################################################################################

echo "[printer] moving $PHY"

iw phy "$PHY" set netns name "$NETNS"


################################################################################
# Create AP interface
################################################################################

echo "[printer] creating wireless interface"

ip netns exec "$NETNS" \
    iw phy "$PHY" interface add "$WIFI_IF" type __ap


################################################################################
# Network setup
################################################################################

echo "[printer] configuring interface"

ip netns exec "$NETNS" \
    ip link set lo up


ip netns exec "$NETNS" \
    ip addr replace "$IP/$PREFIX" dev "$WIFI_IF"


ip netns exec "$NETNS" \
    ip link set "$WIFI_IF" up


################################################################################
# Firewall
################################################################################

echo "[printer] loading firewall"

ip netns exec "$NETNS" \
    nft -f "$CFG/nftables.conf"


################################################################################
# Avahi configuration
################################################################################

mkdir -p /etc/avahi/services

cp "$CFG/airprint.service" \
   /etc/avahi/services/airprint.service


################################################################################
# Start services
################################################################################

echo "[printer] starting hostapd"

ip netns exec "$NETNS" \
    hostapd "$CFG/hostapd.conf" \
    >> /var/log/printer-hostapd.log 2>&1 &

PIDS+=($!)

sleep 3


echo "[printer] starting dnsmasq"

ip netns exec "$NETNS" \
    dnsmasq \
    --conf-file="/etc/dnsmasq.d/printer.conf" \
    --keep-in-foreground \
    >> /var/log/printer-dnsmasq.log 2>&1 &

PIDS+=($!)

sleep 2


echo "[printer] starting avahi"

ip netns exec "$NETNS" \
    avahi-daemon \
    --no-chroot \
    >> /var/log/printer-avahi.log 2>&1 &

PIDS+=($!)

sleep 2


echo "[printer] starting cups"

#-c "$CFG/cupsd.conf" \
ip netns exec "$NETNS" \
    cupsd \
    -f \
    >> /var/log/printer-cups.log 2>&1 &

PIDS+=($!)


echo "[printer] ready"


################################################################################
# Wait forever
################################################################################

wait

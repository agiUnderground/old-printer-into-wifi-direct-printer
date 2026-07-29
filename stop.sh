#!/usr/bin/env bash

set -euo pipefail

NETNS="printer"

echo "[printer] stopping"

if ip netns list | grep -q "^$NETNS"; then
    ip netns exec "$NETNS" pkill hostapd || true
    ip netns exec "$NETNS" pkill dnsmasq || true
    ip netns exec "$NETNS" pkill avahi-daemon || true
    ip netns exec "$NETNS" pkill cupsd || true

    sleep 2

    ip netns delete "$NETNS" || true
fi

rm -f /etc/avahi/services/airprint.service

echo "[printer] stopped"

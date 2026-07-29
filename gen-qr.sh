#!/usr/bin/bash

SSID=$(grep '^ssid=' "config/hostapd.conf" | cut -d= -f2)
PASS=$(grep '^wpa_passphrase=' "config/hostapd.conf" | cut -d= -f2)

# default s value is 3
# -s 8 \
# you probably need to change WPA to something more reasonable btw
qrencode \
  -o qr.png \
  -l H \
  "WIFI:T:WPA;S:${SSID};P:${PASS};;"

qrencode \
  -t ANSIUTF8 \
  "WIFI:T:WPA;S:${SSID};P:${PASS};;"

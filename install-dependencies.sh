#!/bin/bash

sudo apt update

sudo apt install \
    cups \
    cups-filters \
    avahi-daemon \
    avahi-utils \
    hostapd \
    dnsmasq \
    nftables \
    iproute2 \
    qrencode

# What each package is for
#
# Package           Purpose
#
# cups              Print server
# cups-filters      PDF/image filters
# avahi-daemon      AirPrint/mDNS advertisement
# avahi-utils       Debugging (avahi-browse)
# hostapd           Wi-Fi hotspot
# dnsmasq           DHCP + DNS
# nftables          Firewall
# iproute2          ip netns and namespace management
# qrencode          Generate Wi-Fi QR code

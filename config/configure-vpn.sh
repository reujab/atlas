#!/bin/bash -eux
set -o pipefail

uid=$(id -u atlas-streamer)

# Make atlas-streamer use tun0 by default
ip route add table 1 default dev tun0 $(ip route show dev tun0 | cut -d ' ' -f2-)
ip rule add uidrange "$uid-$uid" table 1

# Block ipv6 packets unless the destination is localhost.
ip6tables -I OUTPUT 1 -m owner --uid-owner "$uid" -j DROP
ip6tables -I OUTPUT 1 -m owner --uid-owner "$uid" --dest localhost -j ACCEPT

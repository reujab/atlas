#!/bin/bash -eux
set -o pipefail

uid=$(id -u atlas-streamer)

for ip_v in 4 6; do
	ip -$ip_v route add table 1 default dev tun0 $(ip -$ip_v route show dev tun0 | head -n1 | cut -d' ' -f2-)
	ip -$ip_v rule add uidrange "$uid-$uid" table 1
done

# # Block ipv6 packets unless the destination is localhost.
# ip6tables -I OUTPUT 1 -m owner --uid-owner "$uid" -j DROP
# ip6tables -I OUTPUT 1 -m owner --uid-owner "$uid" --dest localhost -j ACCEPT

#!/bin/bash
# 20181220 Kirby

# Add to crontab with:
# @reboot /root/tunreceiver.sh >/tmp/tunreceiver.cronjob 2>&1

export PATH=/bin:/usr/bin:/sbin:/usr/sbin

defdev=$(ip route ls |egrep '^default via ' |sed -e 's/.* dev \([A-Za-z0-9]*\) .*/\1/')
defip=$(ip route ls |egrep -v '^default via '|egrep " dev $defdev .* link src "  |sed -e 's/.* link src \([0-9]*\.[0-9]*\.[0-9]*\.[0-9]*\).*/\1/' |awk '{print $1}' |head -1)

if ! echo $defip |egrep -q "^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$"
then
    echo "FAILURE: unable to determine external IP"
    exit 1
fi

modprobe gre
ip tunnel add softtap mode gre local $defip ttl 255
ip link set softtap up
ip link set softtap mtu 9000



#!/bin/bash
# https://github.com/mtkirby/mksofttap
# 20190112 Kirby

# Add to crontab with:
# @reboot /root/tunreceiver.sh >/tmp/tunreceiver.cronjob 2>&1

export PATH=/bin:/usr/bin:/sbin:/usr/sbin

defdev=$(ip route ls |egrep '^default via ' |sed -e 's/.* dev \([A-Za-z0-9]*\) .*/\1/')
defip=$(ip addr ls $defdev |egrep 'inet .* scope\s+global'|head -1 |awk '{print $2}' |cut -d'/' -f1)

if ! echo $defip |egrep -q "^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$"
then
    echo "FAILURE: unable to determine external IP"
    exit 1
fi

lsmod |egrep -q '^gre ' || modprobe gre
ip tunnel add softtap mode gre local $defip ttl 255
ip link set softtap up
ip link set softtap mtu 9000



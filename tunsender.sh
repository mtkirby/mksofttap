#!/bin/bash
# https://github.com/mtkirby/mksofttap
# 20181222 Kirby

# Add to crontab with:
# @reboot /root/tunsender IPofIDSserver >/tmp/tunsender 2>&1

export PATH=/bin:/usr/bin:/sbin:/usr/sbin

if ip link ls softtap >/dev/null 2>&1
then
    echo "softtap tunnel already setup"
    exit 1
fi

if ! echo $1 |egrep -q "^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$"
then
    echo "Usage: $0 IPofIDSserver"
    exit 1
fi

defdev=$(ip route ls |egrep '^default via ' |sed -e 's/.* dev \([A-Za-z0-9]*\) .*/\1/')

modprobe gre
ip tunnel add softtap mode gre remote $1 ttl 255
ip link set softtap up
ip link set softtap mtu 9000
ip route add 127.1.1.1 dev softtap
for defip in $(ip addr ls $defdev |egrep 'inet .* scope\s+global' |awk '{print $2}' |cut -d'/' -f1)
do
    if ! echo $defip |egrep -q "^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$"
    then
        echo "skipping bad defip $defip"
        continue
    fi
    
    for portgroup in 1:21 23:513 515:872 874:2048 2050:65535
    do
        iptables -t mangle -A POSTROUTING -p tcp -m tcp -m multiport --sports $portgroup -s $defip -j TEE --gateway 127.1.1.1
        iptables -t mangle -A PREROUTING -p tcp -m tcp -m multiport --dports $portgroup -d $defip -j TEE --gateway 127.1.1.1
        iptables -t mangle -A POSTROUTING -p udp -m udp -m multiport --sports $portgroup -s $defip -j TEE --gateway 127.1.1.1
        iptables -t mangle -A PREROUTING -p udp -m udp -m multiport --dports $portgroup -d $defip -j TEE --gateway 127.1.1.1
    done
done


#!/bin/bash
# https://github.com/mtkirby/mksofttap
# 20190108 Kirby

# Add to crontab with:
# @reboot /root/tunsender IPofIDSserver >/tmp/tunsender 2>&1

export PATH=/bin:/usr/bin:/sbin:/usr/sbin

# Ports that will not be sent.
ignoreports='22,514,873,2049,5666,5901,9997'

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

    for proto in tcp udp
    do
        iptables -t mangle -N tapin-${proto}-${defip} >/dev/null 2>&1
        iptables -t mangle -N tapout-${proto}-${defip} >/dev/null 2>&1

        iptables -t mangle -A PREROUTING -p $proto -m $proto -m multiport -d $defip ! --dports $ignoreports -j tapin-${proto}-${defip} 
        iptables -t mangle -A tapin-${proto}-${defip}  -p $proto -m $proto -m multiport -d $defip ! --sports $ignoreports -j TEE --gateway 127.1.1.1

        iptables -t mangle -A POSTROUTING -p $proto -m $proto -m multiport -s $defip ! --dports $ignoreports -j tapout-${proto}-${defip}
        iptables -t mangle -A tapout-${proto}-${defip} -p $proto -m $proto -m multiport -s $defip ! --sports $ignoreports -j TEE --gateway 127.1.1.1
    done
done



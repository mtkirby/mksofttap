#!/bin/bash
# https://github.com/mtkirby/mksofttap
# 20190110 Kirby

# Add to crontab with:
# @reboot /root/tunsender.sh IPofIDSserver >/tmp/tunsender 2>&1

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

modprobe gre
ip tunnel add softtap mode gre remote $1 ttl 255
ip link set softtap up
ip link set softtap mtu 9000
ip route add 127.1.1.1 dev softtap
ip -6 route add fe80:1:1:1:1:1:1:1/128 dev softtap

ignorePorts='22,514,636,873,2049,9997'


################################################################################
# METHOD 1: anything crossing the interfaces.  Useful for hypervisors.
for ifdev in $(ip route ls |egrep ' via .* dev ' |sed -e 's/.* dev \([A-Za-z0-9]*\) .*/\1/' |sort -u |grep -v softtap)
do
    for proto in tcp udp
    do
        iptables -t mangle -N tapin-${proto}-${ifdev} >/dev/null 2>&1
        iptables -t mangle -N tapout-${proto}-${ifdev} >/dev/null 2>&1

        iptables -t mangle -A PREROUTING -p $proto -m $proto -m multiport -i $ifdev ! --dports $ignorePorts -j tapin-${proto}-${ifdev} 
        iptables -t mangle -A tapin-${proto}-${ifdev}  -p $proto -m $proto -m multiport -i $ifdev ! --sports $ignorePorts -j TEE --gateway 127.1.1.1

        iptables -t mangle -A POSTROUTING -p $proto -m $proto -m multiport -o $ifdev ! --dports $ignorePorts -j tapout-${proto}-${ifdev}
        iptables -t mangle -A tapout-${proto}-${ifdev} -p $proto -m $proto -m multiport -o $ifdev ! --sports $ignorePorts -j TEE --gateway 127.1.1.1


        ip6tables -t mangle -N tapin-${proto}-${ifdev} >/dev/null 2>&1
        ip6tables -t mangle -N tapout-${proto}-${ifdev} >/dev/null 2>&1

        ip6tables -t mangle -A PREROUTING -p $proto -m $proto -m multiport -i $ifdev ! --dports $ignorePorts -j tapin-${proto}-${ifdev} 
        ip6tables -t mangle -A tapin-${proto}-${ifdev}  -p $proto -m $proto -m multiport -i $ifdev ! --sports $ignorePorts -j TEE --gateway fe80:1:1:1:1:1:1:1

        ip6tables -t mangle -A POSTROUTING -p $proto -m $proto -m multiport -o $ifdev ! --dports $ignorePorts -j tapout-${proto}-${ifdev}
        ip6tables -t mangle -A tapout-${proto}-${ifdev} -p $proto -m $proto -m multiport -o $ifdev ! --sports $ignorePorts -j TEE --gateway fe80:1:1:1:1:1:1:1
    done
done
################################################################################

################################################################################
# METHOD 2: IP specific to this host
#
#defdev=$(ip route ls |egrep '^default via ' |sed -e 's/.* dev \([A-Za-z0-9]*\) .*/\1/')
#for defip in $(ip addr ls $defdev |egrep 'inet .* scope\s+global' |awk '{print $2}' |cut -d'/' -f1)
#do
#    if ! echo $defip |egrep -q "^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$"
#    then
#        echo "skipping bad defip $defip"
#        continue
#    fi
#    
#    for proto in tcp udp
#    do
#        iptables -t mangle -N tapin-${proto}-${defip} >/dev/null 2>&1
#        iptables -t mangle -N tapout-${proto}-${defip} >/dev/null 2>&1
#
#        iptables -t mangle -A PREROUTING -p $proto -m $proto -m multiport -d $defip ! --dports $ignorePorts -j tapin-${proto}-${defip} 
#        iptables -t mangle -A tapin-${proto}-${defip}  -p $proto -m $proto -m multiport -d $defip ! --sports $ignorePorts -j TEE --gateway 127.1.1.1
#
#        iptables -t mangle -A POSTROUTING -p $proto -m $proto -m multiport -s $defip ! --dports $ignorePorts -j tapout-${proto}-${defip}
#        iptables -t mangle -A tapout-${proto}-${defip} -p $proto -m $proto -m multiport -s $defip ! --sports $ignorePorts -j TEE --gateway 127.1.1.1
#
#
#        ip6tables -t mangle -N tapin-${proto}-${defip} >/dev/null 2>&1
#        ip6tables -t mangle -N tapout-${proto}-${defip} >/dev/null 2>&1
#
#        ip6tables -t mangle -A PREROUTING -p $proto -m $proto -m multiport -d $defip ! --dports $ignorePorts -j tapin-${proto}-${defip} 
#        ip6tables -t mangle -A tapin-${proto}-${defip}  -p $proto -m $proto -m multiport -d $defip ! --sports $ignorePorts -j TEE --gateway fe80:1:1:1:1:1:1:1
#
#        ip6tables -t mangle -A POSTROUTING -p $proto -m $proto -m multiport -s $defip ! --dports $ignorePorts -j tapout-${proto}-${defip}
#        ip6tables -t mangle -A tapout-${proto}-${defip} -p $proto -m $proto -m multiport -s $defip ! --sports $ignorePorts -j TEE --gateway fe80:1:1:1:1:1:1:1
#    done
#done
################################################################################




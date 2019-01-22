#!/bin/bash
# https://github.com/mtkirby/mksofttap
# 20190121 Kirby

# If you want to tap a bridge, run "modprobe br_netfilter"
# Then check to make sure nf-call for iptables is set to 1 (default).
# net.bridge.bridge-nf-call-arptables = 1
# net.bridge.bridge-nf-call-ip6tables = 1
# net.bridge.bridge-nf-call-iptables = 1

# Add to crontab with: # @reboot /root/tunsender.sh IPofIDSserver >/tmp/tunsender.log 2>&1

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

if ! which ipset >/dev/null 2>&1
then
    echo "ipset not found.  Trying to install package."
    if which dnf >/dev/null 2>&1
    then
        dnf install -y ipset
    elif which yum >/dev/null 2>&1
    then
        yum install -y ipset
    elif which apt-get >/dev/null 2>&1
    then
        apt-get install -y ipset
    else
        echo "FAILURE: You must install ipset"
        exit 1
    fi
fi

modprobe gre >/dev/null 2>&1
ip tunnel add softtap mode gre remote $1 ttl 255
ip link set softtap up
ip link set softtap mtu 9000
ip route add 127.1.1.1 dev softtap
ip -6 route add fe80:1:1:1:1:1:1:1/128 dev softtap

ignorePorts='22,88,123,161,389,443,514,636,873,1514,2049,5666,5901,8089,9997'

ipset destroy mynets >/dev/null 2>&1
ipset create mynets hash:net
ipset add mynets 192.168.0.0/16
ipset add mynets 172.16.0.0/12
ipset add mynets 10.0.0.0/8
ipset add mynets 169.254.0.0/16

ipset destroy my6nets >/dev/null 2>&1
ipset create my6nets hash:net family ipv6
ipset add my6nets fd00::/8
ipset add my6nets fe80::/10

################################################################################
for ifdev in $(ip route ls |egrep ' via .* dev ' |sed -e 's/.* dev \([A-Za-z0-9]*\) .*/\1/' |sort -u |grep -v softtap)
do
    for proto in tcp udp
    do
        #
        # IPv4 mynets networks.
        # These rules exclude the $ignorePorts
        #
        iptables -t mangle -N tapin-${proto}-${ifdev} >/dev/null 2>&1
        iptables -t mangle -N tapout-${proto}-${ifdev} >/dev/null 2>&1

        # inbound mynets networks
        iptables -t mangle -A PREROUTING -p $proto -m $proto -i $ifdev \
            -m set --match-set mynets src \
            -m multiport ! --dports $ignorePorts \
            -j tapin-${proto}-${ifdev}
        iptables -t mangle -A tapin-${proto}-${ifdev} -p $proto -m $proto -i $ifdev \
            -m set --match-set mynets src \
            -m multiport ! --sports $ignorePorts \
            -j TEE --gateway 127.1.1.1

        # outbound mynets networks
        iptables -t mangle -A POSTROUTING -p $proto -m $proto -o $ifdev \
            -m set --match-set mynets dst \
            -m multiport ! --dports $ignorePorts \
            -j tapout-${proto}-${ifdev}
        iptables -t mangle -A tapout-${proto}-${ifdev} -p $proto -m $proto -o $ifdev \
            -m set --match-set mynets dst \
            -m multiport ! --sports $ignorePorts \
            -j TEE --gateway 127.1.1.1

        #
        # IPv4 NOT mynets networks.
        # These rules do not use $ignorePorts
        #
        # inbound not mynets networks
        iptables -t mangle -A PREROUTING -p $proto -m $proto -i $ifdev \
            -m set ! --match-set mynets src \
            -j TEE --gateway 127.1.1.1

        # outbound not mynets networks
        iptables -t mangle -A POSTROUTING -p $proto -m $proto -o $ifdev \
            -m set ! --match-set mynets dst \
            -j TEE --gateway 127.1.1.1


        #
        # IPv6 my6nets networks
        # These rules exclude the $ignorePorts
        #
        ip6tables -t mangle -N tapin-${proto}-${ifdev} >/dev/null 2>&1
        ip6tables -t mangle -N tapout-${proto}-${ifdev} >/dev/null 2>&1

        # inbound my6nets networks
        ip6tables -t mangle -A PREROUTING -p $proto -m $proto -i $ifdev \
            -m set --match-set my6nets src \
            -m multiport ! --dports $ignorePorts \
            -j tapin-${proto}-${ifdev} 
        ip6tables -t mangle -A tapin-${proto}-${ifdev}  -p $proto -m $proto -i $ifdev \
            -m set --match-set my6nets src \
            -m multiport ! --sports $ignorePorts \
            -j TEE --gateway fe80:1:1:1:1:1:1:1

        # outbound my6nets networks
        ip6tables -t mangle -A POSTROUTING -p $proto -m $proto -o $ifdev \
            -m set --match-set my6nets dst \
            -m multiport ! --dports $ignorePorts \
            -j tapout-${proto}-${ifdev}
        ip6tables -t mangle -A tapout-${proto}-${ifdev} -p $proto -m $proto -o $ifdev \
            -m set --match-set my6nets dst \
            -m multiport ! --sports $ignorePorts \
            -j TEE --gateway fe80:1:1:1:1:1:1:1


        #
        # IPv6 NOT my6nets networks.
        # These rules do not use $ignorePorts
        #
        # inbound not my6nets networks
        ip6tables -t mangle -A PREROUTING -p $proto -m $proto -i $ifdev \
            -m set ! --match-set my6nets src \
            -j TEE --gateway fe80:1:1:1:1:1:1:1

        # outbound not my6nets networks
        ip6tables -t mangle -A POSTROUTING -p $proto -m $proto -o $ifdev \
            -m set ! --match-set my6nets dst \
            -j TEE --gateway fe80:1:1:1:1:1:1:1

    done

    echo "TAP set on interface $ifdev"
done
################################################################################


#!/bin/bash
# 20181220 Kirby

export PATH=/bin:/usr/bin:/sbin:/usr/sbin

IFS=$'\n'

rm -f /tmp/untun.sh >/dev/null 2>&1
for i in $(iptables-save -t mangle|grep 127.1.1.1|sed -e 's/^-A P/-D P/')
do 
    echo "iptables -t mangle $i" >>/tmp/untun.sh
done
bash /tmp/untun.sh

ip tunnel del softtap
ip link del softtap


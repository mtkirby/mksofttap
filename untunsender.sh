#!/bin/bash
# 20190115 Kirby

export PATH=/bin:/usr/bin:/sbin:/usr/sbin

iptables -t mangle -F >/dev/null 2>&1
iptables -t mangle -X >/dev/null 2>&1
ip6tables -t mangle -F >/dev/null 2>&1
ip6tables -t mangle -X >/dev/null 2>&1
ipset destroy mynets >/dev/null 2>&1
ipset destroy my6nets >/dev/null 2>&1
ip tunnel del softtap >/dev/null 2>&1
ip link del softtap >/dev/null 2>&1


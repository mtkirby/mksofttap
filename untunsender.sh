#!/bin/bash
# 20181224 Kirby

export PATH=/bin:/usr/bin:/sbin:/usr/sbin

iptables -t mangle -F >/dev/null 2>&1
ip tunnel del softtap >/dev/null 2>&1
ip link del softtap >/dev/null 2>&1


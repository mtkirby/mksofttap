mksofttap is a couple scripts that creates a software tap on Linux.
It uses a gre tunnel with iptables to forward packets to an IDS server.
I will add IPv6 in the future.

My IDS is a SELKS server running Suricata.

You will need to add a 127.1.1.1 alias interface.  See network-sample for what I added to /etc/network/interfaces on my SELKS box.

On the hypervisor machines, I have a bootup cronjob to send packets to SELKS, IP 192.168.1.121, like so: @reboot /root/tunsender.sh 192.168.1.121 >/tmp/tunsender.cronlog 2>&1

On the SELKS server, I have a bootup cronjob to recieve packets like so: @reboot /root/tunreceiver.sh >/tmp/tunreceiver.cronjob 2>&1

You can filter out ports in the tunsender.sh by modifying the portgroups.  It would be wise to filter out rsync and nfs.

mksofttap is a couple scripts that creates a software tap on Linux.
It uses a half-GRE tunnel with iptables to forward packets to an IDS server.
The IDS server simply sets up a GRE endpoint with no network attachment.  

My IDS is a SELKS server running Suricata.

On the hypervisor machines, I have a bootup cronjob to send packets to SELKS, IP 192.168.1.121, like so: @reboot /root/tunsender.sh 192.168.1.121 >/tmp/tunsender.cronlog 2>&1

On the SELKS server, I have a bootup cronjob to recieve packets like so: @reboot /root/tunreceiver.sh >/tmp/tunreceiver.cronjob 2>&1
Setup Suricata to listen on the external interface.  Suricata will see the GRE traffic as it passes to the softtap interface.

You can filter out ports in the tunsender.sh by modifying the ignoreports variable.  It would be wise to filter out rsync, syslog, and nfs.

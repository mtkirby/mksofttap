mksofttap is a virtual/software network TAP for Linux.  It uses a half-GRE tunnel and iptables mangle rules to copy packets to a network IDS.  There is no running agent.  The TAP runs in the kernel.

The IDS server simply sets up a GRE endpoint with no network attachment.  
The iptables mangle rules copies the matched packets through the GRE tunnel.

My IDS is a SELKS server running Suricata.

On the hosts, I have a bootup cronjob to send packets to SELKS, IP 192.168.1.121, like so: 
```sh
@reboot /root/tunsender.sh 192.168.1.121 >/tmp/tunsender.log 2>&1
```

On the SELKS server, I have a bootup cronjob to recieve packets like so: 
```sh
@reboot /root/tunreceiver.sh > /tmp/tunreceiver.log 2>&1
```

Setup Suricata to listen on the external interface.  Suricata will see the GRE traffic as it passes to the softtap interface.

You can filter out ports, for internal-to-internal networks, in tunsender.sh by modifying the ignoreports variable.  It would be wise to filter out rsync, syslog, and nfs.


If you want to tap a bridge, run "modprobe br_netfilter"
Then check to make sure nf-call for iptables is set to 1 (default).
```sh
net.bridge.bridge-nf-call-arptables = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
```



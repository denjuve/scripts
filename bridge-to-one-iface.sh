#!/bin/bash
iface = eth1
bridge = br-joint
gtw_ip = 192.168.122.1
my_ip = 192.168.122.151
prefix = 24
checking_ip = 192.168.122.152

exec 1>log.log 2>&1
sleep 20
ip addr flush dev $iface
brctl addif $bridge $iface
ip address add $my_ip/$prefix dev $bridge

if ping $checking_ip -c 10
then
ip r add default via $gtw_ip dev $bridge
else
ip addr flush dev $bridge
brctl delif $bridge $iface
ip address add $my_ip/$prefix dev $iface
fi

if ping $checking_ip -c 10
then echo ok
else
reboot now
fi

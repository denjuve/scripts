#!/bin/bash
iface= em1
bridge= br-joint
gtw_ip= 10.5.0.1
my_ip= 10.5.1.18
prefix= 16
checking_ip= 10.5.1.14

exec 1>log.log 2>&1
sleep 20
ip link set $bridge up
ip addr flush dev $iface
brctl addif $bridge $iface
ip address add $my_ip/$prefix dev $bridge
ip r del default
ip r add default via $gtw_ip dev $bridge

if ping $checking_ip -c 10
then
ip r add default via $gtw_ip dev $bridge
else
ip addr flush dev $bridge
brctl delif $bridge $iface
ip address add $my_ip/$prefix dev $iface
ip r del default
ip r add default via $gtw_ip dev $iface
fi

if ping $checking_ip -c 10
then echo ok
else
reboot now
fi

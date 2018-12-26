#!/bin/bash
exec 1>log.log 2>&1
sleep 20
ip addr flush dev em1
brctl addif br-joint em1
ip address add 192.168.122.151/16 dev br-joint

if ping 192.168.122.152 -c 10
then
echo ok
else
ip addr flush dev br-joint
brctl delif br-joint em1
ip address add 192.168.122.151/16 dev em1
fi

if ping 192.168.122.152 -c 10
then echo ok
else
reboot now
fi

#!/bin/bash

########## cleaning VMs ############
while read -r FILE; do

virsh destroy $FILE
virsh undefine $FILE

rm -f /home/virt-vm-local/${$FILE}.qcow2
rm -f /home/virt-vm-local/${$FILE}.iso

done < "$1"

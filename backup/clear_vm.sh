#!/bin/bash

cd `dirname $0`
vm_ID=$1
virsh destroy $vm_ID
rm -f /var/lib/libvirt/images/$vm_ID.img
for i in `grep "mac address" ../xml/$vm_ID.xml | sed "s/.*'\(.*\)'../\1/"`; do
    sed -i "/$i/d" ../dnsmasq/*.host
done
rm -f ../xml/$vm_ID.xml

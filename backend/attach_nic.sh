#!/bin/bash

cd `dirname $0`
source ../cloudrc

[ $# -lt 2 ] && echo "$0 <vm_ID> <vlan> [vm_ip] [vm_mac]" && exit -1

vm_ID=$1
vlan=$2
vm_ip=$3
vm_mac=$4

vm_br=br$vlan
if [ ! -d /sys/devices/virtual/net/$vm_br ]; then
    brctl addbr $vm_br
    ip link set $vm_br up
    ip link add vxlan-$vlan type vxlan id $vlan group ${vxlan_mcast_addr} dev ${vxlan_interface}
    ip link set vxlan-$vlan up
    brctl addif $vm_br vxlan-$vlan
fi
virsh attach-interface $vm_ID bridge $vm_br --model virtio --mac $vm_mac
[ $? -eq 0 ] && echo "NIC $vm_mac in vlan $vlan was attached successfully to $vm_ID."
virsh dumpxml $vm_ID > $xml_dir/$vm_ID.xml

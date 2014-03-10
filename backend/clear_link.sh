#!/bin/bash

cd `dirname $0`
source ../cloudrc

[ $# -lt 1 ] && echo "$0 <vlan>" && exit -1

vlan=$1
vm_br=br$vlan
dns_pid=`ps -ef | grep dnsmasq | grep "\<interface=ns-$vlan\>" | awk '{print $2}'`
kill $dns_pid; kill -9 $dns_pid
ip link set tap-$vlan down
ip link set $vm_br down
brctl delbr $vm_br
ip netns exec vlan$vlan ip link set lo down
ip netns exec vlan$vlan ip link del ns-$vlan
ip link del tap-$vlan
udevadm settle
ip netns del vlan$vlan
rm -f $dmasq_dir/vlan$vlan.*
echo "Resource of network $vlan was cleared."

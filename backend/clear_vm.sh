#!/bin/bash

cd `dirname $0`
source ../cloudrc

[ $# -lt 1 ] && die "$0 <vm_ID>"

vm_ID=$1
mac_addrs=`virsh dumpxml $vm_ID | grep "mac address" | sed "s/.*='\(.*\)'.*/\1/"`
for i in $mac_addrs; do
    vx_dev=`bridge fdb show | grep $i | grep vxlan`
    bridge fdb del $i dev $vx_dev
done
virsh destroy $vm_ID
rm -f /var/lib/libvirt/images/$vm_ID.img
rm -f $xml_dir/$vm_ID.xml
echo "|:-COMMAND-:| /opt/cloudland/scripts/frontback/`basename $0` $vm_ID"

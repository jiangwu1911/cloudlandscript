#!/bin/bash

cd `dirname $0`
source ../cloudrc

[ $# -lt 1 ] && die "$0 <vm_ID>"

vm_ID=$1
virsh destroy $vm_ID
rm -f /var/lib/libvirt/images/$vm_ID.img
rm -f $xml_dir/$vm_ID.xml
echo "|:-COMMAND-:| /opt/cloudland/scripts/frontback/`basename $0` $vm_ID"

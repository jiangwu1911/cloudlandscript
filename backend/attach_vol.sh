#!/bin/bash

cd `dirname $0`
source ../cloudrc

[ $# -lt 3 ] && echo "$0 <vm_ID> <volume> <device>" && exit -1

vm_ID=$1
vol_name=$2
device=$3
vol_file=$volume_dir/$vol_name.disk

virsh attach-disk $vm_ID $vol_file $device
if [ $? -eq 0 ]; then
    echo "|:-COMMAND-:| /opt/cloudland/scripts/frontback/`basename $0` $vm_ID $vol_name $device"
else
    echo "|:-COMMAND-:| /opt/cloudland/scripts/frontback/`basename $0` '' '$vol_name' ''"
fi
virsh dumpxml $vm_ID > $xml_dir/$vm_ID.xml >/dev/null 2>&1

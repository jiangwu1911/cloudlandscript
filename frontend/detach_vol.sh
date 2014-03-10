#!/bin/bash

cd `dirname $0`
source ../cloudrc

[ $# -lt 2 ] && echo "$0 <user> <volume>" && exit -1

owner=$1
vol_name=$2

sql_ret=`sqlite3 $db_file "select inst_id, device from volume where name='$vol_name'"`
vm_ID=`echo $sql_ret | cut -d'|' -f1`
device=`echo $sql_ret | cut -d'|' -f2`
[ -n "$vm_ID" ] || die "Volume was not attached!"
[ "$device" == "vda" ] && die "Instance is runing based on it, please delete VM first!"

hyper_id=`sqlite3 $db_file "select id from compute where hyper_name=(select hyper_name from instance where inst_id='$vm_ID')"`
[ -n "$hyper_id" ] && /opt/cloudland/bin/sendmsg "inter $hyper_id" "/opt/cloudland/scripts/backend/`basename $0` $vm_ID $vol_name $device"
sqlite3 $db_file "update volume set inst_id='$vm_ID', device='$device' where name='$vol_name'"
echo "$vm_ID|$vol_name|detaching"

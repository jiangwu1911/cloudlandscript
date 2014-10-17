#!/bin/bash

cd `dirname $0`
source ../cloudrc

[ $# -lt 2 ] && echo "$0 <user> <vm_ID> [description]" && exit -1

owner=$1
vm_ID=$2
desc=$3

num=`sqlite3 $db_file "select count(*) from instance where inst_id='$vm_ID' and owner='$owner' and status='running'"`
[ $num -lt 1 ] && die "VM not running or not VM owner!"
hyper_id=`sqlite3 $db_file "select id from compute where hyper_name=(select hyper_name from instance where inst_id='$vm_ID')"`
hyper_IP=`sqlite3 $db_file "select ip_addr from compute where id=$hyper_id"`
download_url=http://$hyper_IP/snapshot/$vm_ID.qcow2
[ -n "$hyper_id" ] && /opt/cloudland/bin/sendmsg "inter $hyper_id" "/opt/cloudland/scripts/backend/`basename $0` $vm_ID"
num=`sqlite3 $db_file "select count(*) from snapshot where inst_id='$vm_ID'"`
if [ $num = 0 ]; then 
    sqlite3 $db_file "insert into snapshot (download_url, owner, inst_id, description, status) values ('$download_url', '$owner', '$vm_ID', '$desc', 'creating')"
else
    sqlite3 $db_file "update snapshot set status='creating' where inst_id='$vm_ID'"
fi
sqlite3 $db_file "select inst_id, status from snapshot where inst_id='$vm_ID'"

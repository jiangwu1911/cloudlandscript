#!/bin/bash

cd `dirname $0`
source ../cloudrc

[ $# -lt 3 ] && echo "$0 <user> <vm_ID> <vlan> [vm_ip]" && exit -1

owner=$1
vm_ID=$2
vlan=$3
vm_ip=$4

num=`sqlite3 $db_file "select count(vlan) from netlink where vlan='$vlan' and (owner='$owner' or shared='true' COLLATE NOCASE)"`
[ $num -lt 1 ] && die "No vlan $vlan belonging to $owner!"
num=`sqlite3 $db_file "select count(*) from instance where inst_id='$vm_ID' and owner='$owner' and status='running'"`
[ $num -lt 1 ] && die "VM not running or not VM owner!"

num=0
while [ -z "$vm_name" -a $num -lt 120 ]; do
    vm_name=`sqlite3 $db_file "select hname from instance where inst_id='$vm_ID' and status='running'"`
    let num=$num+1
    sleep 1
done
vm_mac="52:54:"`openssl rand -hex 4 | sed 's/\(..\)/\1:/g; s/.$//'`

[ -z "$vm_ip" ] && vm_ip=`sqlite3 $db_file "select IP from address where vlan='$vlan' and allocated='false' limit 1"`
sqlite3 $db_file "update address set allocated='true', mac='$vm_mac', instance='$vm_ID' where IP='$vm_ip'"
router=`sqlite3 $db_file "select id from compute where hyper_name=(select router from netlink where vlan='$vlan')"`
[ "$router" -ge 0 ] && /opt/cloudland/bin/sendmsg "inter $router" "/opt/cloudland/scripts/backend/set_host.sh $vlan $vm_mac $vm_name $vm_ip"
hyper_id=`sqlite3 $db_file "select id from compute where hyper_name=(select hyper_name from instance where inst_id='$vm_ID')"`
[ -n "$hyper_id" ] && /opt/cloudland/bin/sendmsg "inter $hyper_id" "/opt/cloudland/scripts/backend/`basename $0` $vm_ID $vlan $vm_ip $vm_mac"
#sqlite3 $db_file "update volume set inst_id='$vm_ID', device='', instance='$vm_ID' where IP='$vm_ip'"
echo "$vm_ID|$vlan|attaching"

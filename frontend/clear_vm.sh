#!/bin/bash

cd `dirname $0`
source ../cloudrc

[ $# -lt 2 ] && echo "$0 <user> <vm_ID>" && exit -1

owner=$1
vm_ID=$2
sql_ret=`sqlite3 $db_file "select vlan, ip_addr, mac_addr, hyper_name, owner from instance where inst_id='$vm_ID' and owner='$owner' and status!='launching'"`
[ -z "$sql_ret" ] && die "No such VM!"

vlan=`echo $sql_ret | cut -d'|' -f1`
vm_ip=`echo $sql_ret | cut -d'|' -f2`
vm_mac=`echo $sql_ret | cut -d'|' -f3`
hyper=`echo $sql_ret | cut -d'|' -f4`
owner=`echo $sql_ret | cut -d'|' -f4`

sqlite3 $db_file "update instance set deleted=datetime('now'), status='deleted' where inst_id='$vm_ID'"

ids=`sqlite3 $db_file "select id from address where instance='$vm_ID' and allocated='true'"`
for i in $ids; do
    sql_ret=`sqlite3 $db_file "select vlan, IP, mac from address where id='$i'"`
    vl=`echo $sql_ret | cut -d'|' -f1`
    ip=`echo $sql_ret | cut -d'|' -f2`
    mac=`echo $sql_ret | cut -d'|' -f3`
    rt=`sqlite3 $db_file "select id from compute where hyper_name=(select router from netlink where vlan='$vl')"`
    /opt/cloudland/bin/sendmsg "inter $rt" "/opt/cloudland/scripts/backend/del_host.sh $vl $mac $ip"
    sqlite3 $db_file "update address set allocated='false' where IP='$ip'"
done

hyper_id=`sqlite3 $db_file "select id from compute where hyper_name='$hyper'"`
if [ -n "$hyper_id" ]; then
    /opt/cloudland/bin/sendmsg "inter $hyper_id" "/opt/cloudland/scripts/backend/`basename $0` $vm_ID"
else
    /opt/cloudland/bin/sendmsg "toall" "/opt/cloudland/scripts/backend/`basename $0` $vm_ID"
fi
echo "$vm_ID|deleted"

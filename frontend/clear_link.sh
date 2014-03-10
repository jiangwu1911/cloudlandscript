#!/bin/bash

cd `dirname $0`
source ../cloudrc

[ $# -lt 2 ] && echo "$0 <user> <vlan>" && exit -1

owner=$1
vlan=$2
num=`sqlite3 $db_file "select count(*) from netlink where vlan='$vlan' and owner='$owner'"`
[ $num -lt 1 ] && die "Not the vlan $vlan owner!"
num=`sqlite3 $db_file "select count(*) from network where vlan='$vlan'"`
[ $num -ge 1 ] && die "Vlan has network!"

sqlite3 $db_file "delete from netlink where vlan='$vlan'"

hyper=`echo $sql_ret | cut -d'|' -f3`
hyper_id=`sqlite3 $db_file "select id from compute where hyper_name='$hyper'"`
/opt/cloudland/bin/sendmsg "inter $hyper_id" "/opt/cloudland/scripts/backend/`basename $0` $vlan"
echo "$vlan|deleted"

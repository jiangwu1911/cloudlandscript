#!/bin/bash

cd `dirname $0`
source ../cloudrc

[ $# -lt 2 ] && echo "$0 <user> <vlan> <network>" && exit -1

owner=$1
vlan=$2
network=$3

num=`sqlite3 $db_file "select count(*) from netlink where vlan='$vlan' and owner='$owner'"`
[ $num -lt 1 ] && die "Not the vlan owner!"
num=`sqlite3 $db_file "select count(*) from instance where vlan='$vlan' and status='running'"`
[ $num -ge 1 ] && die "The network is being used by instance(s)!"
sql_ret=`sqlite3 $db_file "select gateway, start_address, netmask from network where network='$network'"`
gateway=`echo $sql_ret | cut -d'|' -f1`
start_addr=`echo $sql_ret | cut -d'|' -f2`
netmask=`echo $sql_ret | cut -d'|' -f3`
ip_addrs=`sqlite3 $db_file "select IP from address where vlan='$vlan' and allocated='true'"`
for i in $ip_addrs; do
    [ "$i" == "$start_addr" -o "$i" == "$gateway" ] && continue;
    net=`ipcalc -n $i $netmask | cut -d'=' -f2`
    [ "$network" == "$net" ] && die "The network has address(es) in use!"
done

tag_id=`sqlite3 $db_file "select id from network where network='$network' and vlan='$vlan'"`
sqlite3 $db_file "delete from network where id='$tag_id'"
sqlite3 $db_file "delete from address where network='$network' and vlan='$vlan'"

router=`sqlite3 $db_file "select router from netlink where vlan='$vlan'"`
hyper_id=`sqlite3 $db_file "select id from compute where hyper_name='$router'"`
[ $hyper_id -ge 0 ] && /opt/cloudland/bin/sendmsg "inter $hyper_id" "/opt/cloudland/scripts/backend/`basename $0` $vlan $tag_id"
echo "$network|deleted"

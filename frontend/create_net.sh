#!/bin/bash

cd `dirname $0`
source ../cloudrc

[ $# -lt 2 ] && echo "$0 <user> <vlan> <network> [netmask] [gateway] [start_ip] [end_ip]" && exit -1

owner=$1
vlan=$2
network=$3
netmask=$4
gateway=$5
start_ip=$6
end_ip=$7
has_gw='false'

[ "$vlan" -ge 4095 -o "$owner" == "admin" ] || die "Vlan number must be >= 4095"

ipcalc -c "$network" >/dev/null 2>&1
[ $? -eq 0 ] || die "Invalid network!"
ipcalc -c "$netmask" >/dev/null 2>&1
[ $? -eq 0 ] || die "Invalid netmask!"
ipcalc -c "$gateway" >/dev/null 2>&1
if [ $? -eq 0 ]; then
    has_gw='true'
    net=`ipcalc -n $gateway $netmask | cut -d'=' -f2`
    [ "$network" == "$net" ] || die "Invalid gateway!"
fi
if [ -n "$start_ip" ]; then
    net=`ipcalc -n $start_ip $netmask | cut -d'=' -f2`
    [ "$network" == "$net" ] || die "Invalid start_ip!"
else
    let ip=`inet_aton $network`+1
    start_ip=`inet_ntoa $ip`
fi
if [ -n "$end_ip" ]; then
    net=`ipcalc -n $end_ip $netmask | cut -d'=' -f2`
    [ "$network" == "$net" ] || die "Invalid end_ip!"
else
    let ip=`inet_aton $(ipcalc -b $network $netmask | cut -d'=' -f2)`-1
    end_ip=`inet_ntoa $ip`
fi

num=`sqlite3 $db_file "select count(*) from netlink where owner='$owner' and vlan='$vlan'"`
[ $num -eq 1 ] || die "Now vlan $vlan owner"
quota=`sqlite3 $db_file "select net_limit from quota where role=(select role from users where username='$owner')"`
[ $quota -ge 0 -a $num -ge $quota ] && die "Your quota is used up!"

[ -z "$gateway" ] && gateway="$start_ip" && has_gw='false'
if [ -z "$gateway" ]; then
    n=`echo $network | cut -d'.' -f4`
    let n=$n+1
    gateway=`echo $network | cut -d'.' -f1-3`.$n
    start_ip=$gateway
fi
if [ -z "$end_ip" ]; then
    bcast_ip=`ipcalc -b $network $netmask | cut -d= -f2`
    n=`echo $bcast_ip | cut -d'.' -f4`
    let n=$n-1
    end_ip=`echo $bcast_ip | cut -d'.' -f1-3`.$n
fi

sqlite3 $db_file "insert into network (vlan, network, netmask, gateway, start_address, end_address) values ($vlan, '$network', '$netmask', '$gateway', '$start_ip', '$end_ip')" 
if [ "$has_gw" == 'true' ]; then
    sqlite3 $db_file "insert into address (IP, allocated, vlan, network) values ('$gateway', 'true', '$vlan', '$network')"
fi
if [ -n "$network" ]; then
    [ "$start_ip" != "$gateway" ] && sqlite3 $db_file "insert into address (IP, allocated, vlan, network) values ('$start_ip', 'true', '$vlan', '$network')"

    ip=`inet_aton $start_ip`
    end=`inet_aton $end_ip`
    while [ $ip -lt $end ]; do
        let ip=$ip+1
        sqlite3 $db_file "insert into address (IP, allocated, vlan, network) values ('`inet_ntoa $ip`', 'false', '$vlan', '$network')"
    done
fi

tag_id=`sqlite3 $db_file "select id from network where vlan='$vlan' and network='$network'"`
hyper_id=`sqlite3 $db_file "select id from compute where hyper_name=(select router from netlink where vlan='$vlan')"`
/opt/cloudland/bin/sendmsg "inter $hyper_id" "/opt/cloudland/scripts/backend/`basename $0` $vlan $network $netmask $gateway $start_ip $end_ip $tag_id"
echo "$network|created"

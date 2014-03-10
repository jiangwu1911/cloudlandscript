#!/bin/bash

cd `dirname $0`
source ../cloudrc

[ $# -lt 2 ] && echo "$0 <user> <vlan> [shared(true|false)] [description]" && exit -1

owner=$1
vlan=$2
shared=$3
desc=$4

[ "$vlan" -ge 4095 -o "$owner" == "admin" ] || die "Vlan number must be >= 4095"

num=`sqlite3 $db_file "select count(*) from netlink where vlan='$vlan'"`
[ $num -eq 0 ] || die "Vlan alreay exists!"
num=`sqlite3 $db_file "select count(*) from netlink where owner='$owner'"`
quota=`sqlite3 $db_file "select net_limit from quota where role=(select role from users where username='$owner')"`
[ $quota -ge 0 -a $num -ge $quota ] && die "Your quota is used up!"

[ -z "$shared" ] && shared='false'
sqlite3 $db_file "insert into netlink(vlan, owner, router, shared, description) values ($vlan, '$owner', 'NO_ROUTER', '$shared', '$desc')" 

echo "$vlan|created"

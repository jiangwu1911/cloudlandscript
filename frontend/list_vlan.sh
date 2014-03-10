#!/bin/bash

cd `dirname $0`
source ../cloudrc

[ $# -lt 1 ] && echo "$0 <user>" && exit -1

owner=$1
sqlite3 $db_file "select vlan, network, netmask, gateway, start_address, end_address, owner from network where owner='$owner' or shared='true' COLLATE NOCASE"

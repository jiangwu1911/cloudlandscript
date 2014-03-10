#!/bin/bash

cd `dirname $0`
source ../cloudrc

[ $# -lt 2 ] && echo "$0 <vlan> <hyper>" && exit -1

vlan=$1
hyper=$2

sqlite3 $db_file "update netlink set router='$hyper' where vlan='$vlan'"


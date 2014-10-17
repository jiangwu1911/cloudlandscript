#!/bin/bash
cd `dirname $0`
source ../cloudrc

[ $# -lt 1 ] && echo "$0 <user> <inst_id>" && exit -1
owner=$1
inst_id=$2
sqlite3 $db_file "select download_url from snapshot where inst_id='$inst_id' and status!='deleted'"


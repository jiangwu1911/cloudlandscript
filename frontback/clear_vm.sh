#!/bin/bash

cd `dirname $0`
source ../cloudrc

[ $# -lt 1 ] && echo "$0 <vm_ID>" && exit -1

vm_ID=$1

sqlite3 $db_file "update volume set inst_id='', device='' where inst_id='$vm_ID'"

#!/bin/bash

cd `dirname $0`
source ../cloudrc

[ $# -lt 2 ] && echo "$0 <user> <file>" && exit -1

owner=$1
img_file=$2


rm -f $cache_dir/$img_file
num=`sqlite3 $db_file "select count(*) from image where name='$img_file' and owner='$owner'"`
[ $num -ge 1 ] || die "No such image!"
sqlite3 $db_file "delete from image where name='$img_file'"
#swift -A $swift_url -U $swift_user -K $swift_pass delete images $img_file >/dev/null 2>&1
echo "$img_file|deleted"

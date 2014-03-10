#!/bin/bash

cd `dirname $0`
source ../cloudrc

[ $# -lt 1 ] && echo "$0 <user>" && exit -1

owner=$1
sqlite3 $db_file "select name, size, platform, description, owner from image where owner='$owner' or shared='true' COLLATE NOCASE"

#!/bin/bash

cd `dirname $0`
source ../cloudrc

function avail_memory()
{
    free -m | awk '/^Mem:/ {print ($4 + $7)}'
}

function avail_disk()
{
    df --block-size=10m /var | awk '/^\// {print $4}'  
}

function avail_cpu()
{
    vmstat | tail -1 | awk '{print $15}' 
}

function current_io()
{
    sar -d 2 1 | tail -1 | awk '{print $4, $5}'
}

function current_RXTX()
{
    let interval=$RANDOM%10+1
    res1=`cat /proc/net/dev | grep "$vxlan_interface:" | cut -d: -f2-`
    sleep $interval
    res2=`cat /proc/net/dev | grep "$vxlan_interface:" | cut -d: -f2-`
    echo $res1 $res2 | awk '{printf "%d %d\n", ($17 - $1) * 8 / "'$interval'", ($25 - $9) * 8 / "'$interval'"}'
}

while true; do
    echo `avail_memory` `avail_disk` `avail_cpu` `current_RXTX` `current_io`
    let intval=$RANDOM%5+1
    sleep $intval
done

#!/bin/bash

cd `dirname $0`
source ../cloudrc

[ $# -lt 4 ] && echo "$0 <user> <image> <vlan> <mac> [name] [ip] [cpu] [memory(m)] [disk_inc(G)] [hyper] [metadata]" && exit -1

owner=$1
img_name=$2
vlan=$3
vm_mac=$4
vm_name=$5
vm_ip=$6
vm_cpu=$7
vm_mem=$8
disk_inc=$9
hyper=${10}
metadata=${11}
vm_ID=`date +%m%d%H%M%S-%N`
vm_mem=${vm_mem%[m|M]}

if [ -f "$volume_dir/$img_name.disk" ]; then
    vm_ID=$img_name
    num=`sqlite3 $db_file "select count(*) from instance where inst_id='$vm_ID' and status!='deleted'"`
    [ $num -gt 0 ] && die "Existing instance is using volume $vm_ID!"
fi
if [ -n "$disk_inc" ]; then
    disk_inc=${disk_inc%%[G|g]} 
    [ $disk_inc -gt 0 -a $disk_inc -le $disk_inc_limit ] || die "Invalid disk increase size $disk_inc!"
fi
[ -z "$vm_cpu" ] && vm_cpu=1
[ -z "$vm_mem" ] && vm_mem=256
[ $vm_cpu -le $cpu_limit -a $vm_cpu -gt 0 ] || die "Valid cpu number is 1 - $cpu_limit!"
[ $vm_mem -le $mem_limit -a $vm_mem -gt 128 ] || die "Valid memory is 128 - $mem_limit!"
num=`sqlite3 $db_file "select count(*) from instance where owner='$owner' and status!='deleted'"`
quota=`sqlite3 $db_file "select inst_limit from quota where role=(select role from users where username='$owner')"`
[ $quota -ge 0 -a $num -ge $quota ] && die "Quota is used up!"
num=`sqlite3 $db_file "select count(*) from netlink where vlan='$vlan' and (owner='$owner' or shared='true' COLLATE NOCASE)"`
[ $num -lt 1 ] && die "Not authorised to launch vm on vlan $vlan!"

if [ -n "$vm_ip" ]; then
    allocated=`sqlite3 $db_file "select IP from address where vlan='$vlan' and IP='$vm_ip'"`
    [ "$allocated" != "false" ] && die "IP $vm_ip is not available!"
fi
[ -z "$vm_ip" ] && vm_ip=`sqlite3 $db_file "select IP from address where vlan='$vlan' and allocated='false' limit 1"`
[ -z "$vm_ip" ] && die "No IP address is avalable"
sqlite3 $db_file "update address set allocated='true' where IP='$vm_ip'"
[ -z "$vm_name" ] && vm_name=HOST-`echo $vm_ip | tr '.' '-'`

dns_host=/opt/cloudland/dnsmasq/vlan$vlan.host
dns_opt=/opt/cloudland/dnsmasq/vlan$vlan.opts
[ -z "$vm_mac" ] && vm_mac="52:54:"`openssl rand -hex 4 | sed 's/\(..\)/\1:/g; s/.$//'`

sqlite3 $db_file "insert into instance (inst_id, hname, vlan, mac_addr, ip_addr, owner, status, image, cpu, memory) values ('$vm_ID', '$vm_name', '$vlan', '$vm_mac', '$vm_ip', '$owner', 'launching', '$img_name', '$vm_cpu', '$vm_mem')"
sqlite3 $db_file "update address set allocated='true', mac='$vm_mac', instance='$vm_ID' where IP='$vm_ip'"
hyper_id=`sqlite3 $db_file "select id from compute where hyper_name='$hyper'"`
router=`sqlite3 $db_file "select id from compute where hyper_name=(select router from netlink where vlan='$vlan')"`
[ "$router" -ge 0 ] && /opt/cloudland/bin/sendmsg "inter $router" "/opt/cloudland/scripts/backend/set_host.sh $vlan $vm_mac $vm_name $vm_ip"
/opt/cloudland/bin/sendmsg "inter $hyper_id" "/opt/cloudland/scripts/backend/`basename $0` '$vm_ID' '$img_name' '$vlan' '$vm_mac' '$vm_name' '$vm_ip' '$vm_cpu' '$vm_mem' '$disk_inc'"
echo "$vm_ID|launching"

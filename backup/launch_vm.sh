#!/bin/bash

cd `dirname $0`
source cloudrc

[ $# -lt 4 ] && echo "$0 <node_no> <image> <vlan> <mac> [name] [ip] [dns] [gateway] [netmask]" && exit 1 
node_no=$1
img_name=$2
vlan=$3
vm_mac=$4
vm_name=$5
vm_ip=$6
vm_dns=$7
vm_gw=$8
vm_mask=$9
vm_ID=`date +%Y-%m-%d-%H-%M-%S-%N`

[ -z "$img_name" ] && img_name=super-rhel65.qcow2
vm_img=/var/lib/libvirt/images/$vm_ID.img
[ -f $vm_img ] && echo "Image already exists!" && exit 0

if [ ! -f ../cache/$img_name ]; then
    cd ../cache
    swift -A $swift_url -U $swift_user -K $swift_pass download images $img_name
    cd -
fi
qemu-img convert -f qcow2 -O raw ../cache/$img_name $vm_img

vm_br=br$vlan
if [ -n "$vm_name" -a -n "$vm_ip" ]; then
    dns_host=/opt/cloudland/dnsmasq/vlan$vlan.host
    dns_opt=/opt/cloudland/dnsmasq/vlan$vlan.opts
    echo "$vm_mac,$vm_name.$cloud_domain,$vm_ip" >> $dns_host
    dns_pid=`ps -ef | grep dnsmasq | grep "\<interface=$vm_br\>" >/dev/null 2>&1`
    [ -n "$dns_pid" ] && kill -HUP $dns_pid
    if [ -z "$dns_pid" ]; then
        pid_file=/opt/cloudland/dnsmasq/vlan$vlan.pid
        /usr/sbin/dnsmasq --no-hosts --no-resolv --strict-order --bind-interfaces --interface=$vm_br --except-interface=lo --pid-file=$pid_file --dhcp-hostsfile=$dns_host --dhcp-optsfile=$dns_opt --leasefile-ro
    fi
fi

cp ../xml/template.xml ../xml/$vm_ID.xml
sed -i "s/VM_ID/$vm_ID/g; s#VM_IMG#$vm_img#g; s/VM_MAC/$vm_mac/g; s/VM_BRIDGE/$vm_br/g;" ../xml/$vm_ID.xml
virsh create ../xml/$vm_ID.xml

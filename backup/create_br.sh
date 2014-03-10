#!/bin/bash

managment_network_device=eth3
CLOUD_FIRST_BOX_IP=`grep "inet addr" | cut -d: -f2 | cut -d' ' -f1`
CLOUD_NETMASK=`grep "inet addr" | cut -d: -f4`
CLOUD_GATEWAY=`route -n | grep "^0.0.0.0" | awk {'print $2'}`

function create_bridge()
{
    mgm_nic=$managment_network_device
    br_name=$1
    ip_addrs=`ip addr show $mgm_nic | grep "inet " | awk '{print $2, $3, $4}'`
    mac_addr=`ifconfig $mgm_nic | grep HWaddr | awk '{print $5}'`
    nic_dir="/etc/sysconfig/network-scripts"

    brctl addbr $br_name
    brctl setfd $br_name 0
    brctl addif $br_name $mgm_nic
    ip link set $br_name up
    sed -i "/BRIDGE=/d" $nic_dir/ifcfg-$mgm_nic
    echo "BRIDGE=$br_name" >> $nic_dir/ifcfg-$mgm_nic
    cat > $nic_dir/ifcfg-$br_name <<EOF
DEVICE=$br_name
TYPE="Bridge"
BOOTPROTO="static"
DELAY=0
IPADDR=${CLOUD_FIRST_BOX_IP}
NETMASK=${CLOUD_NETMASK}
GATEWAY=${CLOUD_GATEWAY}
EOF

    for ip in "$ip_addrs"; do
        ip addr add $ip dev $br_name
    done

    route -n | grep "$mgm_nic$" | awk '{print $1, $2, $3}' |
    while read line; do
        net=`echo $line | cut -d' ' -f1`
        gw=`echo $line | cut -d' ' -f2`
        mask=`echo $line | cut -d' ' -f3`
        route add -net $net netmask $mask gw $gw dev $br_name 2>/dev/null
    done

    for ip in "$ip_addrs"; do
        ip addr del $ip dev $mgm_nic
    done
}

create_bridge br4090

#!/bin/sh

checkzero() {
	NAME="$1"
	VAL="$2"
	if [ -z "$VAL" ]; then
		echo "ERROR: missing $NAME parameter"
		exit 1
	fi
}
#core - core_tun_number,thin_public_address
#thin - core_tun_number,core_public_address,port_forwards
usage() { echo "Usage: $0 -n <CORE_TUN_NUMBER> -t <THIN_PUBLIC_ADDRESS>" 1>&2; exit 1; } 
while getopts "n:t:c:p:" o; do
    case "${o}" in
        n)
            core_tun_number=${OPTARG}
            ;;
        c)
            core_public_address=${OPTARG}
            ;;
        t)
            thin_public_address=${OPTARG}
            ;;
        p)
            port_forwards=${OPTARG}
            ;;
        *)
            usage
        ;;
    esac
done
shift $((OPTIND-1))

core_tun_dev="tun${core_tun_number}"
table_num="${core_tun_number}"
table_name="GW${core_tun_number}"
core_tun_address_octet=$(( (${core_tun_number} * 4) + 1 ))
thin_tun_address_octet=$(( (${core_tun_number} * 4) + 2 ))
core_tun_address="10.0.0.${core_tun_address_octet}"
thin_tun_address="10.0.0.${thin_tun_address_octet}"
hashkey="$core_tun_number--$thin_public_address"

checkzero "core_tun_number" "${core_tun_number}"
checkzero "thin_public_address" "${thin_public_address}"

checkzero "core_tun_dev" "${core_tun_dev}"
checkzero "table_num" "${table_num}"
checkzero "table_name" "${table_name}"
checkzero "core_tun_address_octet" "${core_tun_address_octet}"
checkzero "thin_tun_address_octet" "${thin_tun_address_octet}"
checkzero "core_tun_address" "${core_tun_address}"
checkzero "thin_tun_address" "${thin_tun_address}"
checkzero "hashkey" "${hashkey}"


cd /tmp || exit 1


/sbin/ip tunnel show | /bin/grep ${core_tun_dev}
if [ $? -eq 0 ]; then
	echo "INFO: $hashkey: cleaning tunnel"
	/sbin/ip tunnel del ${core_tun_dev}
fi
echo "INFO: $hashkey: creating tunnel"
/sbin/ip tunnel add ${core_tun_dev} mode gre local $(facter ipaddress) remote ${thin_public_address}
echo "INFO: $hashkey: creating tunnel link"
/sbin/ip link set dev ${core_tun_dev} up
echo "INFO: $hashkey: tunnel address"
/sbin/ip addr | /bin/grep ${core_tun_address}
if [ $? -eq 1 ];then
	/sbin/ip address add ${core_tun_address}/30 dev ${core_tun_dev}
fi


echo "INFO: $hashkey: route table"
grep "${table_num} ${table_name}" /etc/iproute2/rt_tables
if [ $? -eq 1 ]; then
	/bin/echo "${table_num} ${table_name}" >> /etc/iproute2/rt_tables
fi
echo "INFO: $hashkey: route add"
/sbin/ip route add default table ${table_name} via ${thin_tun_address}
echo "INFO: $hashkey: route rule"
/sbin/ip rule add fwmark ${table_num} table ${table_name}


echo "INFO: $hashkey: cleaning backroutes"
iptables-save > /tmp/w3thin.iptables.current
grep -v "w3thin-${table_name}" /tmp/w3thin.iptables.current > /tmp/w3thin.iptables.cleaned
iptables-restore < /tmp/w3thin.iptables.cleaned
rm -f /tmp/w3thin.iptables.current /tmp/w3thin.iptables.cleaned
echo "INFO: $hashkey: iptables backroute"
/sbin/iptables -t mangle -A OUTPUT -s ${core_tun_address} -j MARK --set-mark ${table_num} -m comment --comment "w3thin-${table_name}"

	
echo "INFO: $hashkey: ip forwarding"
/bin/echo 1 > /proc/sys/net/ipv4/ip_forward

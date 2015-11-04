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
usage() { echo "Usage: $0 -n <CORE_TUN_NUMBER> -c <CORE_PUBLIC_ADDRESS> -p <PORT>,<PORT>,..." 1>&2; exit 1; }
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

thin_tun_dev="tunx"
core_tun_address_octet=$(( (${core_tun_number} * 4) + 1 ))
thin_tun_address_octet=$(( (${core_tun_number} * 4) + 2 ))
core_tun_address="10.0.0.${core_tun_address_octet}"
thin_tun_address="10.0.0.${thin_tun_address_octet}"
hashkey="$core_tun_number--$core_public_address"

checkzero "core_tun_number" "${core_tun_number}"
checkzero "core_public_address" "${core_public_address}"
checkzero "port_forwards" "${port_forwards}"

checkzero "thin_tun_dev" "${thin_tun_dev}"
checkzero "core_tun_address_octet" "${core_tun_address_octet}"
checkzero "thin_tun_address_octet" "${thin_tun_address_octet}"
checkzero "core_tun_address" "${core_tun_address}"
checkzero "thin_tun_address" "${thin_tun_address}"
checkzero "hashkey" "${hashkey}"


cd /tmp || exit 1


/sbin/ip tunnel show | /bin/grep ${thin_tun_dev}
if [ $? -eq 0 ]; then
	echo "INFO: $hashkey: cleaning tunnel"
	/sbin/ip tunnel del ${thin_tun_dev}
fi
echo "INFO: $hashkey: creating tunnel"
/sbin/ip tunnel add ${thin_tun_dev} mode gre local $(facter ipaddress) remote ${core_public_address}
echo "INFO: $hashkey: creating tunnel link"
/sbin/ip link set dev ${thin_tun_dev} up
echo "INFO: $hashkey: tunnel address"
/sbin/ip addr | /bin/grep ${thin_tun_address}
if [ $? -eq 1 ];then
	/sbin/ip address add ${thin_tun_address}/30 dev ${thin_tun_dev}
fi


echo "INFO: $hashkey: cleaning redirects"
iptables-save > /tmp/w3thin.iptables.current
grep -v "w3thin" /tmp/w3thin.iptables.current > /tmp/w3thin.iptables.cleaned
iptables-restore < /tmp/w3thin.iptables.cleaned
rm -f /tmp/w3thin.iptables.current /tmp/w3thin.iptables.cleaned
echo "INFO: $hashkey: iptables redirects"
doports=$(echo ${port_forwards} | sed 's/,/ /g')
for all in $doports; do
	/sbin/iptables -t nat -A PREROUTING -p tcp --dport ${all} -j DNAT --to-destination ${core_tun_address}:${all} -m comment --comment "w3thin"
done


echo "INFO: $hashkey: ip forwarding"
/bin/echo 1 > /proc/sys/net/ipv4/ip_forward

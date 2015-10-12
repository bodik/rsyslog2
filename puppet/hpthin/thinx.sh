#!/bin/sh

usage() { echo "Usage: $0 -d <THIN_TUN_DEV> -t <THIN_TUN_ADDRESS> -n <CORE_TUN_NUMBER> -c <CORE_PUBLIC_ADDRESS> -p <PORT>,<PORT>,..." 1>&2; exit 1; }
while getopts "d:t:n:c:" o; do
    case "${o}" in
        d)
            thin_tun_dev=${OPTARG}
            ;;
        t)
            thin_tun_address=${OPTARG}
            ;;
        n)
            core_tun_number=${OPTARG}
            ;;
        c)
            core_public_address=${OPTARG}
            ;;
        p)
            ports=${OPTARG}
            ;;
        *)
            usage
        ;;
    esac
done
shift $((OPTIND-1))

hashkey = "$core_tun_number--$core_public_address"
cd /tmp || exit 1

/sbin/ip tunnel show | /bin/grep ${thin_tun_dev}
if [ $? -eq 0 ]; then
	echo "INFO: $hashkey: cleaning tunnel"
	/sbin/ip tunnel del ${thin_tun_dev}
fi

echo "INFO: $hashkey: cleaning redirects"
iptables-save > /tmp/w3thin.iptables.current
grep -v "w3thin" /tmp/w3thin.iptables.current > /tmp/w3thin.iptables.cleaned
iptables-restore < /tmp/w3thin.iptables.cleaned
rm -f /tmp/w3thin.iptables.current /tmp/w3thin.iptables.cleaned

echo "INFO: $hashkey: creating tunnel"
/sbin/ip tunnel add ${thin_tun_dev} mode gre local ${ipaddress} remote ${core_public_address}

echo "INFO: $hashkey: creating tunnel link"
/sbin/ip link set dev ${thin_tun_dev} up

echo "INFO: $hashkey: tunnel address"
/sbin/ip addr | /bin/grep ${thin_tun_address}
if [ $? -eq 0 ];then
	/sbin/ip address add ${thin_tun_address}/30 dev ${thin_tun_dev}
fi

echo "INFO: $hashkey: iptables redirects"
doports = $(echo ${ports} | sed 's/,/ /')
for all in $doports; do
	/sbin/iptables -t nat -A PREROUTING -p tcp --dport ${all} -j DNAT --to-destination ${core_tun_address}:${all} -m comment --comment "w3thin"
done

echo "INFO: $hashkey: ip forwarding"
/bin/echo 1 > /proc/sys/net/ipv4/ip_forward


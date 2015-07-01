ip tunnel add tun01 mode gre local $(facter ipaddress) remote 147.251.253.58 key 123401
ip link set dev tun01 up
ip address 10.0.0.1/30 dev tun01
echo "1 GW1" >> /etc/iproute2/tables
ip route add default table GW1 via 10.0.0.2
ip rule add fwmark 1 table GW1
iptables -t mangle -A OUTPUT -s 10.0.0.1 -j MARK --set-mark 1

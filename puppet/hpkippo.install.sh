
puppet apply --modulepath=/puppet -e 'include hpkippo'

TCNT=$(mysql -NBe "show tables;" kippo 2>/dev/null | wc -l)
if [ $TCNT -lt "2" ]; then
        echo "INFO: initializing kippo db"
        /usr/bin/mysql -e "create database kippo"
        /usr/bin/mysql kippo < /opt/kippo/doc/sql/mysql.sql
fi

WS=$(/puppet/metalib/avahi.findservice.sh _warden-server._tcp)
if [ -z "$WS" ]; then
	echo "ERROR: cannt discover warden_ca server"
	exit 1
fi
curl http://$(facter fqdn):45444/registerSensor


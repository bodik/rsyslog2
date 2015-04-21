
puppet apply --modulepath=/puppet -e 'include warden3::ca'
puppet apply --modulepath=/puppet -e 'include warden3::server'

TCNT=$(mysql -NBe "show tables;" warden3 2>/dev/null | wc -l)
if [ $TCNT -lt "2" ]; then
        echo "INFO: initializing warden3 db"
        /usr/bin/mysql -e "create database warden3"
        /usr/bin/mysql warden3 < /puppet/warden3/files/opt/warden_server/warden_3.0.sql
fi

/opt/warden_server/warden_server.py list | grep $(facter fqdn) 1>/dev/null 2>/dev/null
if [ $? -eq 0 ]; then
	echo "WARN: client $(facter fqdn) already registered"
else
	echo "INFO: registrering self $(facter fqdn) as warden client"
	/opt/warden_server/warden_server.py register -n puppet_test_client -h $(hostname -f) -r bodik@cesnet.cz
fi

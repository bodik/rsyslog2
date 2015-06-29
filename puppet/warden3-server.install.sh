
puppet apply --modulepath=/puppet -e 'include warden3::ca'
puppet apply --modulepath=/puppet -e 'include warden3::server'

TCNT=$(mysql -NBe "show tables;" warden3 2>/dev/null | wc -l)
if [ $TCNT -lt "2" ]; then
        echo "INFO: initializing warden3 db"
        /usr/bin/mysql -e "create database warden3"
        /usr/bin/mysql warden3 < /puppet/warden3/files/opt/warden_server/warden_3.0.sql
fi

/bin/sh /puppet/warden3/bin/register_sensor.sh -s $(facter fqdn) -n puppet_test_client -d /opt/warden_server


puppet apply --modulepath=/puppet -e 'include hpkippo'

TCNT=$(mysql -NBe "show tables;" kippo 2>/dev/null | wc -l)
if [ $TCNT -lt "2" ]; then
        echo "INFO: initializing kippo db"
        /usr/bin/mysql -e "create database kippo"
        /usr/bin/mysql kippo < /opt/kippo/doc/sql/mysql.sql
fi


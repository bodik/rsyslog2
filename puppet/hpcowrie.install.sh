
pa.sh -e 'include hpcowrie'

TCNT=$(mysql -NBe "show tables;" cowrie 2>/dev/null | wc -l)
if [ $TCNT -lt "2" ]; then
        echo "INFO: initializing cowrie db"
        /usr/bin/mysql -e "create database cowrie"
        /usr/bin/mysql cowrie < /opt/cowrie/doc/sql/mysql.sql
fi


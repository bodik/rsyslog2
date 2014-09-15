grep "input(type=\"imrelp\"" /etc/rsyslog.conf 1>/dev/null 2>/dev/null
if [ $? -eq 0 ]; then
        echo "INFO: RSYSLOGSERVERCHECK ======================="

        echo "INFO: puppet apply --modulepath=/puppet -v --noop --show_diff -e 'include rsyslog::server'"
        puppet apply --modulepath=/puppet -v --noop --show_diff -e 'include rsyslog::server'
fi

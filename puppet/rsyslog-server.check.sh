find /etc/rsyslog.d/ -name '*server-globals.conf' | grep server 1>/dev/null 2>/dev/null
if [ $? -eq 0 ]; then
        echo "INFO: RSYSLOGSERVERCHECK ======================="

        echo "INFO: pa.sh -v --noop --show_diff -e 'include rsyslog::server'"
        pa.sh -v --noop --show_diff -e 'include rsyslog::server'
fi

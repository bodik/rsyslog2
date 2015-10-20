find /etc/rsyslog.d/ -name "meta-remote.conf" | grep meta 1>/dev/null 2>/dev/null
if [ $? -eq 0 ]; then
        echo "INFO: RSYSLOGCLINETCHECK ======================="

        echo "INFO: pa.sh -v --noop --show_diff -e 'include rsyslog::client'"
        pa.sh -v --noop --show_diff -e 'include rsyslog::client'

fi

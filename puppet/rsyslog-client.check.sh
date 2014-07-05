find /etc/rsyslog.d/ -name "meta*" | grep meta 1>/dev/null 2>/dev/null
if [ $? -eq 0 ]; then
        echo "INFO: RSYSLOGCLINETCHECK ======================="

	export FACTER_rsyslog_server=$(avahi-browse -t _syseltcp._tcp --resolve -p | grep "=;.*;IPv4;" | awk -F";" '{print $8}' | xargs host -t A | rev | awk '{print $1}' | rev | sed 's/\.$//')
        for all in avahi rsyslog-client; do
                echo "INFO: puppet apply -v --noop --show_diff $all.pp"
                puppet apply -v --noop --show_diff $all.pp
        done
fi

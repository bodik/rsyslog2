find /etc/rsyslog.d/ -name "meta-remote.conf" | grep meta 1>/dev/null 2>/dev/null
if [ $? -eq 0 ]; then
        echo "INFO: RSYSLOGCLINETCHECK ======================="

	export FACTER_rsyslog_server=$(/puppet/avahi/avahi.findservice.sh _syseltcp._tcp)
        for all in rsyslog-client; do
                echo "INFO: puppet apply --modulepath=/puppet -v --noop --show_diff $all.pp"
                puppet apply -v --modulepath=/puppet --noop --show_diff $all.pp
        done
fi

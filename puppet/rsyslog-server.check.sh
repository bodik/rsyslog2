grep "input(type=\"imrelp\"" /etc/rsyslog.conf 1>/dev/null 2>/dev/null
if [ $? -eq 0 ]; then
        echo "INFO: RSYSLOGSERVERCHECK ======================="

	export FACTER_rediser_server=$(/puppet/avahi/avahi.findservice.sh _rediser._tcp)
        for all in avahi rsyslog-server; do
                echo "INFO: puppet apply -v --noop --show_diff $all.pp"
                puppet apply -v --noop --show_diff $all.pp
        done
fi

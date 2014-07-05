grep  "^\*\.\* :om.*:sysel" /etc/rsyslog.conf /etc/rsyslog.d/* 1>/dev/null 2>/dev/null
if [ $? -eq 0 ]; then
        echo "INFO: RSYSLOGCLINETCHECK ======================="

        for all in rsyslog-client; do
                echo "INFO: puppet apply -v --noop --show_diff $all.pp"
                puppet apply -v --noop --show_diff $all.pp
        done
fi

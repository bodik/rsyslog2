find /etc/rsyslog.d/ -name "meta*"
if [ $? -eq 0 ]; then
        echo "INFO: RSYSLOGCLINETCHECK ======================="

        for all in avahi rsyslog-client; do
                echo "INFO: puppet apply -v --noop --show_diff $all.pp"
                puppet apply -v --noop --show_diff $all.pp
        done
fi

dpkg -l fprobe 1>/dev/null 2>/dev/null
if [ $? -eq 0 ]; then
        echo "INFO: FPROBECHECK ======================="

	export FACTER_rediser_server=$(avahi-browse -t _rediser._tcp --resolve -p | grep "=;.*;IPv4;" | awk -F";" '{print $8}' | xargs host -t A | rev | awk '{print $1}' | rev | sed 's/\.$//')
        for all in avahi fprobe; do
                echo "INFO: puppet apply -v --noop --show_diff $all.pp"
                puppet apply -v --noop --show_diff $all.pp
        done
fi

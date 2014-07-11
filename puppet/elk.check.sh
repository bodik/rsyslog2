dpkg -l elasticsearch logstash 1>/dev/null 2>/dev/null
if [ $? -eq 0 ]; then
        echo "INFO: ELKCHECK ======================="

	#TODO: installed puppet modules
	export FACTER_rediser_server=$(avahi-browse -t _rediser._tcp --resolve -p | grep "=;.*;IPv4;" | awk -F";" '{print $8}' | xargs host -t A | rev | awk '{print $1}' | rev | sed 's/\.$//')

        for all in elk_esd elk_lsl elk_kibana; do
                echo "INFO: puppet apply -v --noop --show_diff $all.pp"
                puppet apply -v --noop --show_diff $all.pp
        done
fi

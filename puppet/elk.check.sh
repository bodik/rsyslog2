dpkg -l elasticsearch logstash 1>/dev/null 2>/dev/null
if [ $? -eq 0 ]; then
        echo "INFO: ELKCHECK ======================="

	#TODO: installed puppet modules
	export FACTER_rediser_server=$(/puppet/avahi.findservice.sh _rediser._tcp)

        for all in elk_esd elk_lsl elk_kibana; do
                echo "INFO: puppet apply -v --noop --show_diff $all.pp"
                puppet apply -v --noop --show_diff $all.pp
        done
fi

dpkg -l elasticsearch logstash1>/dev/null 2>/dev/null
if [ $? -eq 0 ]; then
        echo "INFO: ELKCHECK ======================="

	#TODO: installed puppet modules

        for all in elk_esd elk_logstash elk_kibana; do
                echo "INFO: puppet apply -v --noop --show_diff $all.pp"
                puppet apply -v --noop --show_diff $all.pp
        done
fi

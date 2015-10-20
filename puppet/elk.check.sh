dpkg -l elasticsearch logstash 1>/dev/null 2>/dev/null
if [ $? -eq 0 ]; then
        echo "INFO: ELKCHECK ======================="

        for all in elk::esd elk::lsl elk::kbn; do
                echo "INFO: pa.sh -v --noop --show_diff -e \"include $all\""
		pa.sh -v --noop --show_diff -e "include $all"
        done

fi

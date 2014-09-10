gem list | grep redcarpet 1>/dev/null 2>/dev/null
if [ $? -eq 0 ]; then

        echo "INFO: DOCCHECK ======================="

        for all in doc; do
                echo "INFO: puppet apply -v --noop --show_diff --modulepath=/rsyslog2/doc -e \"include $all\""
		puppet apply -v --noop --show_diff --modulepath=/rsyslog2/doc -e "include $all"
        done


fi

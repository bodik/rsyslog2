dpkg -l mongodb-10gen 1>/dev/null 2>/dev/null
if [ $? -eq 0 ]; then
        echo "INFO: MONGOMINECHECK ======================="


        for all in mongomine::database mongomine::lsl mongomine::rsyslogweb; do
                echo "INFO: puppet apply -v --noop --show_diff --modulepath=/puppet -e \"include $all\""
		puppet apply -v --noop --show_diff --modulepath=/puppet -e "include $all"
        done

fi

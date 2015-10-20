dpkg -l mongodb-10gen 1>/dev/null 2>/dev/null
if [ $? -eq 0 ]; then
        echo "INFO: MONGOMINECHECK ======================="


        for all in mongomine::database mongomine::lsl mongomine::rsyslogweb; do
                echo "INFO: pa.sh -v --noop --show_diff -e \"include $all\""
		pa.sh -v --noop --show_diff -e "include $all"
        done

fi

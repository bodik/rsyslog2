dpkg -l redis-server 1>/dev/null 2>/dev/null
if [ $? -eq 0 ]; then
        echo "INFO: REDISERCHECK ======================="

        for all in rediser; do
                echo "INFO: puppet apply -v --noop --show_diff $all.pp"
                puppet apply -v --noop --show_diff $all.pp
        done
fi

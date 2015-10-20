test -f /etc/init.d/rediser 1>/dev/null 2>/dev/null
if [ $? -eq 0 ]; then
        echo "INFO: REDISERCHECK ======================="

        for all in rediser; do
                echo "INFO: pa.sh -v --noop --show_diff -e \"include $all\""
		pa.sh -v --noop --show_diff -e "include $all"
        done
fi

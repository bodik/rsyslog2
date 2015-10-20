/bin/true 1>/dev/null 2>/dev/null
if [ $? -eq 0 ]; then
        echo "INFO: PHASE2CHECK ======================="

        for all in metalib::base; do
                echo "INFO: puppet apply -v --noop --show_diff --modulepath=/puppet -e \"include $all\""
		puppet apply -v --noop --show_diff --modulepath=/puppet -e "include $all"
        done
fi

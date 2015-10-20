/bin/true 1>/dev/null 2>/dev/null
if [ $? -eq 0 ]; then
        echo "INFO: PHASE2CHECK ======================="

        for all in metalib::base; do
                echo "INFO: pa.sh -v --noop --show_diff -e \"include $all\""
		/puppet/metalib/bin/pa.sh -v --noop --show_diff -e "include $all"
        done
fi

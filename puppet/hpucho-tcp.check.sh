if [ -f /opt/uchotcp/uchotcp.py ]; then
        echo "INFO: HPUCHOTCPCHECK ======================="

        for all in hpucho::tcp; do
                echo "INFO: puppet apply -v --noop --show_diff --modulepath=/puppet -e \"include $all\""
                puppet apply -v --noop --show_diff --modulepath=/puppet -e "include $all"
        done

fi


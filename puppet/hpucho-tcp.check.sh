if [ -f /opt/uchotcp/uchotcp.py ]; then
        echo "INFO: HPUCHOTCPCHECK ======================="

        for all in hpucho::tcp; do
                echo "INFO: pa.sh -v --noop --show_diff -e \"include $all\""
                pa.sh -v --noop --show_diff -e "include $all"
        done

fi


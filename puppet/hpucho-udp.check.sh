if [ -f /opt/uchoudp/uchoudp.py ]; then
        echo "INFO: HPUCHOUDPCHECK ======================="

        for all in hpucho::udp; do
                echo "INFO: pa.sh -v --noop --show_diff -e \"include $all\""
                pa.sh -v --noop --show_diff -e "include $all"
        done

fi


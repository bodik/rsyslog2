if [ -f /opt/uchoudp/uchoudp.py ]; then
        echo "INFO: HPUCHOUDPCHECK ======================="

        for all in hpucho::udp; do
                echo "INFO: puppet apply -v --noop --show_diff --modulepath=/puppet -e \"include $all\""
                puppet apply -v --noop --show_diff --modulepath=/puppet -e "include $all"
        done

fi


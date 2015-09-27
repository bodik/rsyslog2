if [ -f /opt/ucho/ucho.py ]; then
        echo "INFO: HPUCHOCHECK ======================="

        for all in hpucho; do
                echo "INFO: puppet apply -v --noop --show_diff --modulepath=/puppet -e \"include $all\""
                puppet apply -v --noop --show_diff --modulepath=/puppet -e "include $all"
        done

fi


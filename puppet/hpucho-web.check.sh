if [ -f /opt/uchoweb/uchoweb.py ]; then
        echo "INFO: HPUCHOWEBCHECK ======================="

        for all in hpucho::web; do
                echo "INFO: puppet apply -v --noop --show_diff --modulepath=/puppet -e \"include $all\""
                puppet apply -v --noop --show_diff --modulepath=/puppet -e "include $all"
        done

fi


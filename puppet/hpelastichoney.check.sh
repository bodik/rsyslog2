if [ -f /opt/elastichoney/elastichoney ]; then
        echo "INFO: HPELASTICHONEYCHECK ======================="

        for all in hpelastichoney; do
                echo "INFO: puppet apply -v --noop --show_diff --modulepath=/puppet -e \"include $all\""
                puppet apply -v --noop --show_diff --modulepath=/puppet -e "include $all"
        done

fi


if [ -f /opt/cowrie/start.sh ]; then
        echo "INFO: HPCOWRIECHECK ======================="

        for all in hpcowrie; do
                echo "INFO: puppet apply -v --noop --show_diff --modulepath=/puppet -e \"include $all\""
                puppet apply -v --noop --show_diff --modulepath=/puppet -e "include $all"
        done

fi


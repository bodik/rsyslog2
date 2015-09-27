if [ -f /opt/telnetd/telnetd.py ]; then
        echo "INFO: HPTELNETDCHECK ======================="

        for all in hptelnetd; do
                echo "INFO: puppet apply -v --noop --show_diff --modulepath=/puppet -e \"include $all\""
                puppet apply -v --noop --show_diff --modulepath=/puppet -e "include $all"
        done

fi


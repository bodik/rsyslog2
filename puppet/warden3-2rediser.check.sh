if [ -f /opt/warden_2rediser/warden_2rediser.py ]; then
        echo "INFO: WARDEN2REDISERCHECK ======================="

        for all in warden3::2rediser; do
                echo "INFO: puppet apply -v --noop --show_diff --modulepath=/puppet -e \"include $all\""
                puppet apply -v --noop --show_diff --modulepath=/puppet -e "include $all"
        done

fi


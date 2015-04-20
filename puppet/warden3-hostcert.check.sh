if [ -d /opt/hostcert ]; then
        echo "INFO: WARDENHOSTCERTCHECK ======================="

        for all in warden3::hostcert; do
                echo "INFO: puppet apply -v --noop --show_diff --modulepath=/puppet -e \"include $all\""
                puppet apply -v --noop --show_diff --modulepath=/puppet -e "include $all"
        done

fi


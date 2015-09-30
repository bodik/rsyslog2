if [ -f /opt/dionaea/bin/dionaea ]; then
        echo "INFO: HPDIOCHECK ======================="

        for all in hpdio; do
                echo "INFO: puppet apply -v --noop --show_diff --modulepath=/puppet -e \"include $all\""
                puppet apply -v --noop --show_diff --modulepath=/puppet -e "include $all"
        done

fi


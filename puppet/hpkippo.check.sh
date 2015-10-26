if [ -f /opt/kippo/start.sh ]; then
        echo "INFO: HPKIPPOCHECK ======================="

        for all in hpkippo; do
                echo "INFO: puppet apply -v --noop --show_diff --modulepath=/puppet -e \"include $all\""
                puppet apply -v --noop --show_diff --modulepath=/puppet -e "include $all"
        done

fi


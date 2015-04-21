if [ -f /opt/warden_server/warden_server.py ]; then
        echo "INFO: WARDENSERVERCHECK ======================="

        for all in warden3::ca warden3::server; do
                echo "INFO: puppet apply -v --noop --show_diff --modulepath=/puppet -e \"include $all\""
                puppet apply -v --noop --show_diff --modulepath=/puppet -e "include $all"
        done

fi


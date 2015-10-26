if [ -f /opt/warden_server/warden_server.py ]; then
        echo "INFO: WARDENSERVERCHECK ======================="

        for all in warden3::ca warden3::server; do
                echo "INFO: pa.sh -v --noop --show_diff -e \"include $all\""
                pa.sh -v --noop --show_diff -e "include $all"
        done

fi


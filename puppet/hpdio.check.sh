if [ -f /opt/dionaea/bin/dionaea ]; then
        echo "INFO: HPDIOCHECK ======================="

        for all in hpdio; do
                echo "INFO: pa.sh -v --noop --show_diff -e \"include $all\""
                pa.sh -v --noop --show_diff -e "include $all"
        done

fi


if [ -f /opt/telnetd/telnetd.py ]; then
        echo "INFO: HPTELNETDCHECK ======================="

        for all in hptelnetd; do
                echo "INFO: pa.sh -v --noop --show_diff -e \"include $all\""
                pa.sh -v --noop --show_diff -e "include $all"
        done

fi


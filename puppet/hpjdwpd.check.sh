if [ -f /opt/jdwpd/jdwpd.py ]; then
        echo "INFO: HPJDWPDCHECK ======================="

        for all in hpjdwpd; do
                echo "INFO: pa.sh -v --noop --show_diff -e \"include $all\""
                pa.sh -v --noop --show_diff -e "include $all"
        done

fi


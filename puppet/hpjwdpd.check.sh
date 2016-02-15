if [ -f /opt/jwdpd/jwdpd.py ]; then
        echo "INFO: HPJWDPDCHECK ======================="

        for all in hpjwdpd; do
                echo "INFO: pa.sh -v --noop --show_diff -e \"include $all\""
                pa.sh -v --noop --show_diff -e "include $all"
        done

fi


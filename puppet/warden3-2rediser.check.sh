if [ -f /opt/warden_2rediser/warden_2rediser.py ]; then
        echo "INFO: WARDEN2REDISERCHECK ======================="

        for all in warden3::2rediser; do
                echo "INFO: pa.sh -v --noop --show_diff -e \"include $all\""
                pa.sh -v --noop --show_diff -e "include $all"
        done

fi


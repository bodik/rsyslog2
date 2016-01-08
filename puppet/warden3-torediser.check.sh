if [ -f /opt/warden_torediser/warden_torediser.py ]; then
        echo "INFO: WARDENTOREDISERCHECK ======================="

        for all in warden3::torediser; do
                echo "INFO: pa.sh -v --noop --show_diff -e \"include $all\""
                pa.sh -v --noop --show_diff -e "include $all"
        done

fi


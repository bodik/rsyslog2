if [ -f /opt/uchoweb/uchoweb.py ]; then
        echo "INFO: HPUCHOWEBCHECK ======================="

        for all in hpucho::web; do
                echo "INFO: pa.sh -v --noop --show_diff -e \"include $all\""
                pa.sh -v --noop --show_diff -e "include $all"
        done

fi


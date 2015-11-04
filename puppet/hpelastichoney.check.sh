if [ -f /opt/elastichoney/elastichoney ]; then
        echo "INFO: HPELASTICHONEYCHECK ======================="

        for all in hpelastichoney; do
                echo "INFO: pa.sh -v --noop --show_diff -e \"include $all\""
                pa.sh -v --noop --show_diff -e "include $all"
        done

fi


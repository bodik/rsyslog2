if [ -f /etc/default/jenkins ]; then
        echo "INFO: JENKINSCHECK ======================="

        for all in jenkins; do
                echo "INFO: pa.sh --noop --show_diff -e \"include $all\""
		pa.sh -v --noop --show_diff -e "include $all"
        done
fi

if [ -f /etc/default/jenkins ]; then
        echo "INFO: JENKINSCHECK ======================="

        for all in jenkins; do
                echo "INFO: puppet apply -v --noop --show_diff --modulepath=/puppet -e \"include $all\""
		puppet apply -v --noop --show_diff --modulepath=/puppet -e "include $all"
        done
fi

if [ -f /etc/default/jenkins ]; then
        echo "INFO: JENKINSCHECK ======================="

	cd /puppet/jenkins || exit 1
        for all in jenkins; do
                echo "INFO: puppet apply -v --noop --show_diff $all.pp"
                puppet apply -v --noop --show_diff $all.pp
        done
fi

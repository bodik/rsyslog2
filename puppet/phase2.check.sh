/bin/true 1>/dev/null 2>/dev/null
if [ $? -eq 0 ]; then
        echo "INFO: PHASE2CHECK ======================="

        for all in base fail2ban; do
                echo "INFO: puppet apply -v --noop --show_diff $all.pp"
                puppet apply -v --noop --show_diff $all.pp
        done
fi

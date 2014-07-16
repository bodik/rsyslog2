dpkg -l fprobe 1>/dev/null 2>/dev/null
if [ $? -eq 0 ]; then
        echo "INFO: FPROBECHECK ======================="

	export FACTER_rediser_server=$(/puppet/avahi/avahi.findservice.sh _rediser._tcp)
        for all in avahi fprobe; do
                echo "INFO: puppet apply -v --noop --show_diff $all.pp"
                puppet apply -v --noop --show_diff $all.pp
        done
fi

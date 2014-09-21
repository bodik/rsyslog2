
# test if fprobe is just a subcomponent of netflow::nfdump
dpkg -l nfdump 1>/dev/null 2>/dev/null
if [ $? -eq 0 ]; then
	exit 0
fi

dpkg -l fprobe 1>/dev/null 2>/dev/null
if [ $? -eq 0 ]; then
        echo "INFO: FPROBECHECK ======================="

        echo "INFO: puppet apply --modulepath=/puppet -v --noop --show_diff -e 'include netflow::fprobe'"
        puppet apply --modulepath=/puppet -v --noop --show_diff -e 'include netflow::fprobe'

fi

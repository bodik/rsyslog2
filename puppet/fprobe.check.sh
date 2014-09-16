dpkg -l fprobe 1>/dev/null 2>/dev/null
if [ $? -eq 0 ]; then
        echo "INFO: FPROBECHECK ======================="

        echo "INFO: puppet apply --modulepath=/puppet -v --noop --show_diff -e 'include metalib::fprobe'"
        puppet apply --modulepath=/puppet -v --noop --show_diff -e 'include metalib::fprobe'

fi

dpkg -l nfdump 1>/dev/null 2>/dev/null
if [ $? -eq 0 ]; then
        echo "INFO: NFDUMPCHECK ======================="

        echo "INFO: pa.sh -v --noop --show_diff -e 'include netflow::nfdump'"
        pa.sh -v --noop --show_diff -e 'include netflow::nfdump'

fi

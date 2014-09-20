dpkg -l nfdump 1>/dev/null 2>/dev/null
if [ $? -eq 0 ]; then
        echo "INFO: NFDUMPCHECK ======================="

        echo "INFO: puppet apply --modulepath=/puppet -v --noop --show_diff -e 'include netflow::nfdump'"
        puppet apply --modulepath=/puppet -v --noop --show_diff -e 'include netflow::nfdump'

fi

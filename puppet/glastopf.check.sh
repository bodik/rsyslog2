test -d /opt/glastopf 1>/dev/null 2>/dev/null && test ! -d /opt/glastopf/warden
if [ $? -eq 0 ]; then
        echo "INFO: GLASTOPFCHECK ======================="

        echo "INFO: puppet apply --modulepath=/puppet -v --noop --show_diff -e 'include glastopf'"
        puppet apply --modulepath=/puppet -v --noop --show_diff -e 'include glastopf'

fi

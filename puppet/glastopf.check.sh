test -d /opt/glastopf 1>/dev/null 2>/dev/null
if [ $? -eq 0 ]; then
        echo "INFO: GLASTOPFCHECK ======================="

        echo "INFO: pa.sh -v --noop --show_diff -e 'include glastopf'"
        pa.sh -v --noop --show_diff -e 'include glastopf'

fi

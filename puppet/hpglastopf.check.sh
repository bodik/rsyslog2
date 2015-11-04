test -d /opt/glastopf 1>/dev/null 2>/dev/null
if [ $? -eq 0 ]; then
        echo "INFO: HPGLASTOPFCHECK ======================="

        echo "INFO: pa.sh -v --noop --show_diff -e 'include hpglastopf'"
        pa.sh -v --noop --show_diff -e 'include hpglastopf'

fi

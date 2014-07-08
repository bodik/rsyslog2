dpkg -l elasticsearch 1>/dev/null 2>/dev/null
if [ $? -eq 0 ]; then
        echo "INFO: ELASTICSEARCHCHECK ======================="

	#TODO: installed puppet modules

        for all in es-server; do
                echo "INFO: puppet apply -v --noop --show_diff $all.pp"
                puppet apply -v --noop --show_diff $all.pp
        done
fi

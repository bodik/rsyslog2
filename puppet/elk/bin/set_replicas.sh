if [ -z $1 ]; then
        echo "ERROR: no replicas number"
        exit 1
fi


for all in `python /puppet/elk/bin/el_listindex.py | awk '{print $1}'`; do

curl -XPUT "http://localhost:39200/${all}/_settings" -d '
{
    "index" : {
        "number_of_replicas" : '$1'
    }
}
'

done


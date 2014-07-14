if [ -z $1 ]; then
        echo "ERROR: no replicas number"
        exit 1
fi


for all in `python el_listindex.py | awk '{print $1}'`; do

curl -XPUT "10.0.0.1:39200/${all}/_settings" -d '
{
    "index" : {
        "number_of_replicas" : '$1'
    }
}
'

done


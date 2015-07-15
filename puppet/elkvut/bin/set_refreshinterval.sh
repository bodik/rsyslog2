if [ -z $1 ]; then
        echo "ERROR: no refresh interval"
        exit 1
fi


for all in `python /puppet/elkvut/bin/el_listindex.py | awk '{print $1}'`; do

curl -XPUT "http://$(facter ipaddress):39200/${all}/_settings" -d '
{
    "index" : {
        "refresh_interval" : "'$1'"
    }
}
'

done


curl -XPUT "http://$(facter ipaddress):39200/_cluster/settings" -d '
{
  "persistent" : {
    "indices.breaker.fielddata.limit" : "70%",
  }
}
'

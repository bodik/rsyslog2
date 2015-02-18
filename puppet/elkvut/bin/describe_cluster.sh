#!/bin/bash

echo "cluster tools update begin"
sh /puppet/elkvut/bin/forall.sh 'sh /puppet/bootstrap.install.sh 1>/dev/null'
echo "cluster tools update end"

echo "h2. == DESCRIPTION BEGIN"
echo "CLUSTER DESCRIPTION"

echo "h3. === describe.rb begin"
sh /puppet/elkvut/bin/forall.sh 'ruby /puppet/elkvut/bin/describe_node.rb'
echo "== describe.rb end"

echo "h3. === _nodes/_all begin"
curl -XGET "http://$(facter ipaddress):39200/_nodes/_all/os,process,jvm,network,transport,http?pretty=true" 2>/dev/null
echo "=== _nodes/_all end"

echo "h3. === _template begin"
curl -XGET "http://$(facter ipaddress):39200/_template?pretty=true" 2>/dev/null
echo " === _template end"

echo "h3. === show_nodes.sh begin"
sh /puppet/elkvut/bin/show_nodes.sh
echo "=== show_nodes.sh end"

echo "h3. === data to send begin"
find /data/data/ -type f -ls
echo "files count:"
find /data/data/ -type f -ls | wc
echo "files size:"
du -sh /data/data/
echo "=== data to send end"

echo "== DESCRIPTION END"


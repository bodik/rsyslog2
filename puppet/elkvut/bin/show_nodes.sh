#!/bin/bash

NODES=$(cat /puppet/elkvut/nodes)

for all in $NODES; do
        echo -n "$all "
        ssh -o 'ConnectTimeout=3' -o 'StrictHostKeyChecking=no' root@$all '

                A=`cat /root/hostname 2>/dev/null|| echo "NA"`;
                echo -n "$A "

                ps faxu  | grep -v "/tmp/procs" > /tmp/procs
                grep node_stats /tmp/procs 1>/dev/null
                if [ $? == 0 ]; then
                        echo -n "GNS "
                fi
                grep mongod /tmp/procs 1>/dev/null
                if [ $? == 0 ]; then
                        #oldcloud
                        A=`grep shardsvr /tmp/procs|grep mongo|wc -l`
                        if [ ${A} -gt 0 ];then  echo -n "${A}MOSD "; fi
                        A=`grep configsvr /tmp/procs|grep mongo|wc -l`
                        if [ ${A} -gt 0 ];then  echo -n "${A}MOCF "; fi

                        #puppetcloud
                        A=`grep Shard /tmp/procs|grep mongo|wc -l`
                        if [ ${A} -gt 0 ];then  echo -n "${A}MSD "; fi
                        A=`grep shardproxy /tmp/procs|grep mongo|wc -l`
                        if [ ${A} -gt 0 ];then  echo -n "${A}MCF "; fi
                fi
                grep mongos /tmp/procs 1>/dev/null
                if [ $? == 0 ]; then
                        echo -n "MOS "
                fi
                grep elastic /tmp/procs 1>/dev/null
                if [ $? == 0 ]; then
                        cat /home/els/config/elasticsearch.yml /etc/elasticsearch/es01/elasticsearch.yml 2>/dev/null | grep -v "^#" | grep "data:.*false" 1>/dev/null 2>/dev/null
                        if [ $? -eq 0 ]; then
                                #non data node
                                echo -n "ESC "
                        else
                                echo -n "ESD "
                        fi
                fi
                grep logstash /tmp/procs 1>/dev/null
                if [ $? == 0 ]; then
                        A=`grep logstash /tmp/procs|grep esh|wc -l`
                        if [ ${A} -gt 0 ];then  echo -n "${A}LSE "; fi
                        A=`grep logstash /tmp/procs|grep mongo|wc -l`
                        if [ ${A} -gt 0 ];then  echo -n "${A}LSM "; fi
                        A=`grep logstash /tmp/procs|grep warden|wc -l`
                        if [ ${A} -gt 0 ];then  echo -n "${A}LSW "; fi
                        A=`grep logstash /tmp/procs|grep opt/logstash|wc -l`
                        if [ ${A} -gt 0 ];then  echo -n "${A}LSP "; fi
                fi
                grep carbon /tmp/procs 1>/dev/null
                if [ $? == 0 ]; then
                        echo -n "GRA "
                fi
                grep warden-receive-to-mongo /tmp/procs 1>/dev/null
                if [ $? == 0 ]; then
                        echo -n "WARM "
                fi
                grep warden-receive-to-redis /tmp/procs 1>/dev/null
                if [ $? == 0 ]; then
                        echo -n "WARR "
                fi

                A=`uptime | sed 's/.*://'`
                echo -n $A
echo
        '
done


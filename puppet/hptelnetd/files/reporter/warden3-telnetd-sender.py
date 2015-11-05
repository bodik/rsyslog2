#!/usr/bin/python
# -*- coding: utf-8 -*-
#
from warden_client import Client, Error, read_cfg, format_timestamp
from pygtail import Pygtail
from time import time, gmtime, strftime
from math import trunc
from uuid import uuid4
import json
import string
import os
import sys

aconfig = read_cfg('warden_client-telnetd.cfg')
wconfig = read_cfg('warden_client.cfg')
aname = aconfig['name']
wconfig['name'] = aname
aanonymised = aconfig['anonymised']
atargetnet  = aconfig['target_net']
aanonymised = aanonymised if (atargetnet != '0.0.0.0/0') or (aanonymised == 'omit') else '0.0.0.0/0'
wclient = Client(**wconfig)


def fill_addresses(event, src_ip, anonymised, target_net):
	af = "IP4" if not ':' in src_ip else "IP6"
	event['Source'][0][af] = [src_ip]
	if anonymised != 'omit':
		if anonymised == 'yes':
			event['Target'][0]['Anonymised'] = True
			event['Target'][0][af] = [target_net]
		else:
			event['Target'][0][af] = [dst_ip]

	return event


def gen_event_idea_telnetd(client_name, detect_time, conn_count, src_ip, src_port, dst_ip, 
		dst_port, anonymised, target_net,proto, category, data):

        event = {
                "Format": "IDEA0",
                "ID": str(uuid4()),
                "DetectTime": detect_time,
                "Category": [category],
                "Note": "telnetd event",
                "ConnCount": conn_count,
                "Source": [{ "Proto": [proto], "Port": [src_port] }], 
                "Target": [{ "Proto": [proto], "Port": [dst_port] }],
                "Node": [
                        { 
                                "Name": client_name,
                                "Tags": ["Honeypot", "Connection"],
                                "SW": ["telnetd"],
                        }
                ],      
                "Attach": [{ "data": data, "datalen": len(data) }]
        }
        event = fill_addresses(event, src_ip, anonymised, target_net)

        return event


events = []
for line in Pygtail(filename=aconfig.get('logfile'), wait_timeout=0):
	data = json.loads(line)

	a = gen_event_idea_telnetd(
		client_name = aname, 
		detect_time = data['detect_time'], 
		conn_count  = 1, 
		src_ip      = data['src_ip'],
		src_port    = data['src_port'], 
		dst_ip      = data['dst_ip'],
		dst_port    = data['dst_port'],
		anonymised  = aanonymised, 
		target_net  = atargetnet,
		proto       = data['proto'],
		category    = data['category'],
		data        = data['data']	
	)
	#print json.dumps(a)
	events.append(a)

#print json.dumps(events, indent=3)

print "=== Sending ==="
start = time()
ret = wclient.sendEvents(events)

if 'saved' in ret:
	wclient.logger.info("%d event(s) successfully delivered." % ret['saved'])

print "Time: %f" % (time() - start)


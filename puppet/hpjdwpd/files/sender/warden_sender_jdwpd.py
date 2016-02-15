#!/usr/bin/python
# -*- coding: utf-8 -*-
#
from warden_client import Client, Error, read_cfg, format_timestamp
from time import time, gmtime, strftime
from math import trunc
from uuid import uuid4
import json
import string
import os
import sys
import warden_utils_flab as w3u

aconfig = read_cfg('warden_client_jdwpd.cfg')
wconfig = read_cfg('warden_client.cfg')
aclient_name = aconfig['name']
wconfig['name'] = aclient_name
aanonymised = aconfig['anonymised']
aanonymised_net  = aconfig['target_net']
aanonymised = aanonymised if (aanonymised_net != '0.0.0.0/0') or (aanonymised_net == 'omit') else '0.0.0.0/0'
wclient = Client(**wconfig)

def gen_event_idea_jdwpd(detect_time, src_ip, src_port, dst_ip, dst_port, proto, category, method, cstring, data):

        event = {
                "Format": "IDEA0",
                "ID": str(uuid4()),
                "DetectTime": detect_time,
                "Category": [category],
                "Note": "jdwpd event",
                "ConnCount": 1,
                "Source": [{ "Proto": [proto], "Port": [src_port] }], 
                "Target": [{ "Proto": [proto], "Port": [dst_port] }],
                "Node": [
                        { 
                                "Name": aclient_name,
                                "Tags": ["Honeypot", "Connection"],
                                "SW": ["jdwpd"],
                        }
                ],      
                "Attach": [{ "data": data, "datalen": len(data) }]
        }

	if category == 'Attempt.Exploit':
		event["Attach"][0]["smart"] = "Method: %s, Cstring: %s" % (method, cstring)

        event = w3u.IDEA_fill_addresses(event, src_ip, dst_ip, aanonymised, aanonymised_net)

        return event


events = []
try:
	for line in w3u.Pygtail(filename=aconfig.get('logfile'), wait_timeout=0):
		data = json.loads(line)

		a = gen_event_idea_jdwpd(
			detect_time = data['detect_time'], 
			src_ip      = data['src_ip'],
			src_port    = data['src_port'], 
			dst_ip      = data['dst_ip'],
			dst_port    = data['dst_port'],
			proto       = data['proto'],
			category    = data['category'],
			method	    = data['method'],
			cstring	    = data['cstring'],
			data        = data['data']	
		)
		#print json.dumps(a)
		events.append(a)
except:
	pass

print json.dumps(events, indent=3)

print "=== Sending ==="
start = time()
ret = wclient.sendEvents(events)

if 'saved' in ret:
	wclient.logger.info("%d event(s) successfully delivered." % ret['saved'])

print "Time: %f" % (time() - start)


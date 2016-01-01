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

aconfig = read_cfg('warden_client_uchoweb.cfg')
wconfig = read_cfg('warden_client.cfg')
aclient_name = aconfig['name']
wconfig['name'] = aclient_name
aanonymised = aconfig['anonymised']
aanonymised_net  = aconfig['target_net']
aanonymised = aanonymised if (aanonymised_net != '0.0.0.0/0') or (aanonymised_net == 'omit') else '0.0.0.0/0'
wclient = Client(**wconfig)

def gen_event_idea_uchoweb(detect_time, src_ip, src_port, dst_ip, dst_port, proto, data):

        event = {
                "Format": "IDEA0",
                "ID": str(uuid4()),
                "DetectTime": detect_time,
                "Category": ["Other"],
                "Note": "Uchoweb event",
                "ConnCount": 1,
                "Source": [{ "Proto": proto, "Port": [src_port] }],
                "Target": [{ "Proto": proto, "Port": [dst_port] }],
                "Node": [
                        {
                                "Name": aclient_name,
                                "Type": ["Honeypot"],
                                "Tags": ["Honeypot"],
                                "SW": ["Uchoweb"],
                        }
                ],
                "Attach": [{ "request": data, "smart": data["requestline"] }]
        }

        event = w3u.IDEA_fill_addresses(event, src_ip, dst_ip, aanonymised, aanonymised_net)

        return event

events = []
try:
	for line in w3u.Pygtail(filename=aconfig.get('logfile'), wait_timeout=0):
		data = json.loads(line)

		a = gen_event_idea_uchoweb(
			detect_time = data['detect_time'], 
			src_ip      = data['src_ip'],
			src_port    = data['src_port'], 
			dst_ip      = data['dst_ip'],
			dst_port    = data['dst_port'],
			proto       = data['proto'],
			data        = data['data'],	
		)
		
		events.append(a)
except:
	pass
print "=== Sending ==="
start = time()
ret = wclient.sendEvents(events)

if 'saved' in ret:
	wclient.logger.info("%d event(s) successfully delivered." % ret['saved'])

print "Time: %f" % (time() - start)


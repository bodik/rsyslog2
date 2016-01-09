#!/usr/bin/python
# -*- coding: utf-8 -*-
#

from warden_client import Client, Error, read_cfg, format_timestamp
from time import time, gmtime, strftime
from math import trunc
from uuid import uuid4
import os
import sys
import warden_utils_flab as w3u
import dateutil.parser, calendar
import json
import string

aconfig = read_cfg('warden_client_elastichoney.cfg')
wconfig = read_cfg('warden_client.cfg')
aclient_name = aconfig['name']
wconfig['name'] = aclient_name
aanonymised = aconfig['anonymised']
aanonymised_net  = aconfig['target_net']
aanonymised = aanonymised if (aanonymised_net != '0.0.0.0/0') or (aanonymised_net == 'omit') else '0.0.0.0/0'
wclient = Client(**wconfig)

def gen_event_idea_elastichoney(detect_time, src_ip, dst_ip, data):

	event = {
		"Format": "IDEA0",
		"ID": str(uuid4()),
		"DetectTime": detect_time,
		"Category": ["Recon.Scanning", "Test"],
		"Note": "Elastichoney event",
		"ConnCount": 1,
		"Source": [{}],
		"Target": [{ "Proto": ["tcp", "http"], "Port" : [9200] }],
		"Node": [
			{
				"Name": aclient_name,
				"Type": ["Honeypot", "Data"],
				"SW": ["Elastichoney"],
			}
		],
		"Attach": [ { "ehevent": data, "smart": data["type"] } ]
  	}

	event = w3u.IDEA_fill_addresses(event, src_ip, dst_ip, aanonymised, aanonymised_net)
  
	return event


events = []
try:
	for line in w3u.Pygtail(filename=aconfig.get('logfile'), wait_timeout=0):
		#sys.stdout.write(line)
		data = json.loads(line)

		#import pdb; pdb.set_trace()
		#yes gringo ;) text > object > unixtime > text again
		dtime = format_timestamp( calendar.timegm( dateutil.parser.parse(data["@timestamp"]).utctimetuple() ) )
		a = gen_event_idea_elastichoney(
			detect_time = dtime, 
			src_ip = data['source'], 
			dst_ip = data['honeypot'],
			data = data	
		)
		#print json.dumps(a)
		events.append(a)
except:
	pass
#print json.dumps(events, indent=3)

print "=== Sending ==="
start = time()
ret = wclient.sendEvents(events)

if 'saved' in ret:
	wclient.logger.info("%d event(s) successfully delivered." % ret['saved'])

print "Time: %f" % (time() - start)


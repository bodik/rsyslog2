#!/usr/bin/python
# -*- coding: utf-8 -*-
#
# Copyright (C) 2011-2015 Cesnet z.s.p.o
# Use of this source is governed by a 3-clause BSD-style license, see LICENSE file.

from warden_client import Client, Error, read_cfg, format_timestamp
import json
from time import time, gmtime, strftime, sleep
from uuid import uuid4
import sqlite3

DEFAULT_ACONFIG = 'warden_client-glastopf.cfg'
DEFAULT_WCONFIG = 'warden_client.cfg'
DEFAULT_NAME = 'org.example.warden.test'
DEFAULT_AWIN = 5
DEFAULT_ANONYMISED = 'no'
DEFAULT_TARGET_NET = '0.0.0.0/0'

DEFAULT_CON_ATTEMPTS = 3
DEFAULT_CON_RETRY_INTERVAL = 5
DEFAULT_DBFILE  = '/opt/glastopf/db/glastopf.db'


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

def gen_event_idea_g1(client_name, detect_time, conn_count, src_ip, anonymised, target_net, 
	request_url, request_raw, pattern, filename):

	event = {
		"Format": "IDEA0",
		"ID": str(uuid4()),
		"DetectTime": detect_time,
		"Category": ["Other"],
		"Note": "webhoneypot event",
		"ConnCount": conn_count,
		"Source": [{}],
		"Target": [{ "Proto": ["tcp", "http"], "Port" : [80] }],
		"Node": [
			{
				"Name": client_name,
				"Tags": ["Honeypot", "Connection"],
				"SW": ["Glastopf"],
			}
		],
		"Attach": [{ "request_url": request_url, "request_raw": request_raw, "pattern": pattern, "filename": filename }]
	}
	event = fill_addresses(event, src_ip, anonymised, target_net)
	try:
		event["Attach"][0]["smart"] = request_raw.split("\n")[0]
	except:
		pass
	
  
	return event


def main():
	#warden client startup
	aconfig = read_cfg(DEFAULT_ACONFIG)
	wconfig = read_cfg(aconfig.get('warden', DEFAULT_WCONFIG))
	aname = aconfig.get('name', DEFAULT_NAME)
	awin = aconfig.get('awin', DEFAULT_AWIN) * 60
	wconfig['name'] = aname
	wclient = Client(**wconfig)   
	aanonymised = aconfig.get('anonymised', DEFAULT_ANONYMISED)
	if aanonymised not in ['no', 'yes', 'omit']:
		wclient.logger.error("Configuration error: anonymised: '%s' - possible typo? use 'no', 'yes' or 'omit'" % aanonymised)
		sys.exit(2)
	atargetnet  = aconfig.get('target_net', DEFAULT_TARGET_NET)
	aanonymised = aanonymised if (atargetnet != DEFAULT_TARGET_NET) or (aanonymised == 'omit') else DEFAULT_ANONYMISED

	aconattempts = aconfig.get('con_attempts', DEFAULT_CON_ATTEMPTS)
	aretryinterval = aconfig.get('con_retry_interval', DEFAULT_CON_RETRY_INTERVAL)
	adbfile = aconfig.get('dbfile', DEFAULT_DBFILE)


	con = sqlite3.connect(adbfile)
	con.row_factory = sqlite3.Row
	crs = con.cursor()
	events = []


	query =  "SELECT id, strftime('%%s',time ,'utc') as utime, source, request_url, request_raw, pattern, filename \
			FROM events \
			WHERE cast(utime as integer) > (cast(strftime('%%s', 'now') as integer)-%s)" % (awin)
	#print "DEBUG: query=",query

	attempts = 0
	while attempts < aconattempts:
		try:
			crs.execute(query)
			break
		except sqlite3.Error, e:
			attempts += 1
			wclient.logger.info("Info: %s - attempt %d/%d." % (e.args[0], attempts, aconattempts))
			if attempts == aconattempts:
				wclient.logger.error("Error: %s (dbfile: %s)" % (e.args[0], adbfile))
			sleep(aretryinterval)
	
	rows = crs.fetchall()
	
	if con:
		con.close

	etime = format_timestamp(time())
	stime = format_timestamp(time() - awin)

	for row in rows:
		#print row
		dtime = format_timestamp(float(row['utime']))
		source_info = row['source'].split(":")
		a = gen_event_idea_g1(
			client_name = aname, 
			detect_time = dtime, 
			conn_count = 1, 
			src_ip = source_info[0], 
			anonymised = aanonymised, 
			target_net = atargetnet,

			request_url = row['request_url'],
			request_raw = row['request_raw'],
			pattern = row['pattern'],
			filename = row['filename'],
		)
		a['Source'][0]['Port']=[int(source_info[1])]
		#print json.dumps(a)
		events.append(a)

	print "=== Sending ==="
	start = time()
	ret = wclient.sendEvents(events)
  
	if 'saved' in ret:
		wclient.logger.info("%d event(s) successfully delivered." % ret['saved'])

	print "Time: %f" % (time() - start)


if __name__ == "__main__":
    main()


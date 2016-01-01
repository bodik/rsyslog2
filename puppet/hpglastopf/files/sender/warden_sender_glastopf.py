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
import warden_utils_flab as w3u

aconfig = read_cfg('warden_client_glastopf.cfg')
wconfig = read_cfg('warden_client.cfg')
aclient_name = aconfig['name']
wconfig['name'] = aclient_name
aanonymised = aconfig['anonymised']
aanonymised_net  = aconfig['target_net']
aanonymised = aanonymised if (aanonymised_net != '0.0.0.0/0') or (aanonymised_net == 'omit') else '0.0.0.0/0'

awin = aconfig['awin'] * 60
aconattempts = aconfig['con_attempts']
aretryinterval = aconfig['con_retry_interval']
adbfile = aconfig['dbfile']

wclient = Client(**wconfig)


def gen_event_idea_gl(detect_time, src_ip, src_port, request_url, request_raw, pattern, filename):

	event = {
		"Format": "IDEA0",
		"ID": str(uuid4()),
		"DetectTime": detect_time,
		"Category": ["Other"],
		"Note": "webhoneypot event",
		"ConnCount": 1,
		"Source": [{"Port" : [src_port]}],
		"Target": [{ "Proto": ["tcp", "http"], "Port" : [80] }],
		"Node": [
			{
				"Name": aclient_name,
				"Type": ["Honeypot", "Connection"],
				"Tags": ["Honeypot", "Connection"],
				"SW": ["Glastopf"],
			}
		],
		"Attach": [{ 	"request_url" : request_url, 
				"request_raw" : request_raw, 
				"pattern"     : pattern, 
				"filename"    : filename }]
	}

	event = w3u.IDEA_fill_addresses(event, src_ip, "0.0.0.0", aanonymised, aanonymised_net)

	try:
		event["Attach"][0]["smart"] = request_raw.split("\n")[0]
	except:
		pass
	
  
	return event


def main():
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
		a = gen_event_idea_gl(
			detect_time = dtime, 
			src_ip = source_info[0], 
			src_port = int(source_info[1]),
			request_url = row['request_url'],
			request_raw = row['request_raw'],
			pattern = row['pattern'],
			filename = row['filename'],
		)
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


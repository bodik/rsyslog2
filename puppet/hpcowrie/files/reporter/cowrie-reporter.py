#!/usr/bin/python
# -*- coding: utf-8 -*-
#
# na motivy kostejova romanu

from warden_client import Client, Error, read_cfg, format_timestamp
import json
import string
from time import time, gmtime, strftime
from math import trunc
from uuid import uuid4
import os
import sys

DEFAULT_ACONFIG = 'warden_client-kippo.cfg'
DEFAULT_WCONFIG = 'warden_client.cfg'
DEFAULT_NAME = 'org.example.warden.test'
DEFAULT_AWIN = 5
DEFAULT_ANONYMISED = 'no'
DEFAULT_TARGET_NET = '0.0.0.0/0'

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


def gen_event_idea_auth(client_name, detect_time, conn_count, src_ip, dst_ip, anonymised, target_net, 
	username, password, sessionid):

	event = {
		"Format": "IDEA0",
		"ID": str(uuid4()),
		"DetectTime": detect_time,
		"Category": ["Intrusion"],
		"Note": "SSH successfull attempt",
		"ConnCount": conn_count,
		"Source": [{}],
		"Target": [{ "Proto": ["tcp", "ssh"], "Port" : [22] }],
		"Node": [
			{
				"Name": client_name,
				"Tags": ["Honeypot", "Connection", "Auth"],
				"SW": ["Cowrie"],
			}
		],
		"Attach": [{ "sessionid": sessionid, "username": username, "password": password }]
	}
	event = fill_addresses(event, src_ip, anonymised, target_net)
  
	return event


def gen_event_idea_ttylog(client_name, detect_time, conn_count, src_ip, dst_ip, anonymised, target_net, 
	sessionid, ttylog, iinput):

	event = {
		"Format": "IDEA0",
		"ID": str(uuid4()),
		"DetectTime": detect_time,
		"Category": ["Malware.Virus"],
		"Note": "Cowrie ttylog",
		"ConnCount": conn_count,
		"Source": [{}],
		"Target": [{ "Proto": ["tcp", "ssh"], "Port" : [22] }],
		"Node": [
			{
				"Name": client_name,
				"Tags": ["Honeypot", "Data"],
				"SW": ["Cowrie"],
			}
		],
		"Attach": [ { "sessionid": sessionid, "ttylog": ttylog, "iinput": iinput, "smart": iinput } ]
  	}
	event = fill_addresses(event, src_ip, anonymised, target_net)
  
	return event

def gen_event_idea_download(client_name, detect_time, conn_count, src_ip, dst_ip, anonymised, target_net, 
	sessionid, url, outfile):

	event = {
		"Format": "IDEA0",
		"ID": str(uuid4()),
		"DetectTime": detect_time,
		"Category": ["Other"],
		"Note": "Cowrie download",
		"ConnCount": conn_count,
		"Source": [{}],
		"Target": [{ "Proto": ["tcp", "ssh"], "Port" : [22]}],
		"Node": [
			{
				"Name": client_name,
				"Tags": ["Honeypot", "Data"],
				"SW": ["Cowrie"],     
			}
			],
		"Attach": [{ "sessionid": sessionid, "url": url, "outfile": outfile, "smart": url }]
	}
	event = fill_addresses(event, src_ip, anonymised, target_net)
	
	return event





#reporter
import MySQLdb as my
import MySQLdb.cursors as mycursors

import tempfile, subprocess, base64

con = my.connect( host=aconfig['dbhost'], user=aconfig['dbuser'], passwd=aconfig['dbpass'],
       		  db=aconfig['dbname'], port=aconfig['dbport'], cursorclass=mycursors.DictCursor)
crs = con.cursor()
events = []



def get_iinput(sessionid):
	ret = []
       	query = "SELECT GROUP_CONCAT(input SEPARATOR '--SEP--') as i FROM input WHERE session=%s GROUP BY session;"
	crs.execute(query, sessionid)
        rows = crs.fetchall()
        for row in rows:
		ret.append(row["i"])
	return ''.join(ret)


def get_ttylog(sessionid):
	ret = ""
       	query = "SELECT id, session, ttylog FROM ttylog WHERE session=%s;"
	crs.execute(query, sessionid)
        rows = crs.fetchall()
        for row in rows:
		try:
			tf = tempfile.NamedTemporaryFile(delete=False)
			with open(tf.name, 'w') as f:
				f.write(row['ttylog'])
			ret = subprocess.check_output(["/usr/bin/python", "/opt/cowrie/utils/playlog.py", "-m0", tf.name])
		finally:
			os.remove(tf.name)

		#try to dumpit to json to see if there are some binary input and perhaps wrap it to base64
		try:
			a = json.dumps(ret)
		except UnicodeDecodeError as e:
			wclient.logger.warning("wraping binary content")
			ret = base64.b64encode(ret)

	return ret


#success login
query =  "SELECT UNIX_TIMESTAMP(CONVERT_TZ(a.timestamp, @@global.time_zone, '+00:00')) as timestamp, s.ip as sourceip, sn.ip as sensor, a.session as sessionid, a.username as username, a.password as password \
	FROM auth a JOIN sessions s ON s.id=a.session JOIN sensors sn ON s.sensor=sn.id \
	WHERE a.success=1 AND CONVERT_TZ(a.timestamp, @@global.time_zone, '+00:00') > DATE_SUB(UTC_TIMESTAMP(), INTERVAL + %s SECOND) \
	ORDER BY a.timestamp ASC;"
crs.execute(query, awin)
rows = crs.fetchall()
for row in rows:
	#print json.dumps(row)
	dtime = format_timestamp(row['timestamp'])
	a = gen_event_idea_auth(
		client_name = aname, 
		detect_time = dtime, 
		conn_count = 1, 
		src_ip = row['sourceip'], 
		dst_ip = row['sensor'],
		anonymised = aanonymised, 
		target_net = atargetnet,

		username = row['username'],
		password = row['password'],
		sessionid = row['sessionid']
	)
	#print json.dumps(a)
	events.append(a)





#ttylog+iinput reporter
query =  "SELECT UNIX_TIMESTAMP(CONVERT_TZ(s.starttime, @@global.time_zone, '+00:00')) as starttime, s.ip as sourceip, sn.ip as sensor, t.session as sessionid \
          FROM ttylog t JOIN sessions s ON s.id=t.session JOIN sensors sn ON s.sensor=sn.id \
          WHERE CONVERT_TZ(s.starttime, @@global.time_zone, '+00:00') > DATE_SUB(UTC_TIMESTAMP(), INTERVAL + %s SECOND) \
          ORDER BY s.starttime ASC;"
crs.execute(query, awin)
rows = crs.fetchall()
for row in rows:
	#print json.dumps(row)
	dtime = format_timestamp(row['starttime'])
	a = gen_event_idea_ttylog(
		client_name = aname, 
		detect_time = dtime, 
		conn_count = 1, 
		src_ip = row['sourceip'], 
		dst_ip = row['sensor'],
		anonymised = aanonymised, 
		target_net = atargetnet,

		sessionid = row['sessionid'],
		ttylog = get_ttylog(row['sessionid']),
		iinput = get_iinput(row['sessionid'])
	)	
	#print json.dumps(a)
	events.append(a)






#download
query =  "SELECT UNIX_TIMESTAMP(CONVERT_TZ(s.starttime, @@global.time_zone, '+00:00')) as starttime, s.ip as sourceip, sn.ip as sensor, d.session as sessionid, d.url as url, d.outfile as ofile \
	FROM downloads d JOIN sessions s ON s.id=d.session JOIN sensors sn ON s.sensor=sn.id \
	WHERE CONVERT_TZ(s.starttime, @@global.time_zone, '+00:00') > DATE_SUB(UTC_TIMESTAMP(), INTERVAL + %s SECOND) \
	ORDER BY s.starttime ASC;"
crs.execute(query, awin)
rows = crs.fetchall()
for row in rows:
	#print json.dumps(row)
	dtime = format_timestamp(row['starttime'])
	a = gen_event_idea_download(
		client_name = aname, 
		detect_time = dtime, 
		conn_count = 1, 
		src_ip = row['sourceip'], 
		dst_ip = row['sensor'],
		anonymised = aanonymised, 
		target_net = atargetnet,

		sessionid = row['sessionid'],
		url = row['url'],
		outfile = row['ofile']
	)
	#print json.dumps(a)
	events.append(a)


print "=== Sending ==="
start = time()
ret = wclient.sendEvents(events)
#print json.dumps(events, indent=3)

if 'saved' in ret:
	wclient.logger.info("%d event(s) successfully delivered." % ret['saved'])

print "Time: %f" % (time() - start)



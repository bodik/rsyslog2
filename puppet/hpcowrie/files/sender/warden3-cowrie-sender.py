#!/usr/bin/python
# -*- coding: utf-8 -*-
#
# na motivy kostejova romanu

from warden_client import Client, Error, read_cfg, format_timestamp
from time import time, gmtime, strftime
from math import trunc
from uuid import uuid4
import MySQLdb as my
import MySQLdb.cursors as mycursors
import tempfile, subprocess, base64
import json
import string
import os
import sys
import w3utils_flab as w3u

#warden client startup
aconfig = read_cfg('warden_client-cowrie.cfg')
wconfig = read_cfg('warden_client.cfg')
aclient_name = aconfig['name']
wconfig['name'] = aclient_name
aanonymised = aconfig['anonymised']
aanonymised_net  = aconfig['target_net']
aanonymised = aanonymised if (aanonymised_net != '0.0.0.0/0') or (aanonymised_net == 'omit') else '0.0.0.0/0'
awin = aconfig['awin'] * 60

wclient = Client(**wconfig)

def gen_event_idea_cowrie_auth(detect_time, src_ip, dst_ip, username, password, sessionid):

	event = {
		"Format": "IDEA0",
		"ID": str(uuid4()),
		"DetectTime": detect_time,
		"Category": ["Intrusion"],
		"Note": "SSH successfull attempt",
		"ConnCount": 1,
		"Source": [{}],
		"Target": [{ "Proto": ["tcp", "ssh"], "Port" : [22] }],
		"Node": [
			{
				"Name": aclient_name,
				"Tags": ["Honeypot", "Connection", "Auth"],
				"SW": ["Cowrie"],
			}
		],
		"Attach": [{ "sessionid": sessionid, "username": username, "password": password }]
	}

	event = w3u.IDEA_fill_addresses(event, src_ip, dst_ip, aanonymised, aanonymised_net)
  
	return event


def gen_event_idea_cowrie_ttylog(detect_time, src_ip, dst_ip, sessionid, ttylog, iinput):

	event = {
		"Format": "IDEA0",
		"ID": str(uuid4()),
		"DetectTime": detect_time,
		"Category": ["Malware.Virus"],
		"Note": "Cowrie ttylog",
		"ConnCount": 1,
		"Source": [{}],
		"Target": [{ "Proto": ["tcp", "ssh"], "Port" : [22] }],
		"Node": [
			{
				"Name": aclient_name,
				"Tags": ["Honeypot", "Data"],
				"SW": ["Cowrie"],
			}
		],
		"Attach": [ { "sessionid": sessionid, "ttylog": ttylog, "iinput": iinput, "smart": iinput } ]
  	}
	
	event = w3u.IDEA_fill_addresses(event, src_ip, dst_ip, aanonymised, aanonymised_net) 
 
	return event


def gen_event_idea_cowrie_download(detect_time, src_ip, dst_ip,	sessionid, url, outfile):

	event = {
		"Format": "IDEA0",
		"ID": str(uuid4()),
		"DetectTime": detect_time,
		"Category": ["Other"],
		"Note": "Cowrie download",
		"ConnCount": 1,
		"Source": [{}],
		"Target": [{ "Proto": ["tcp", "ssh"], "Port" : [22]}],
		"Node": [
			{
				"Name": aclient_name,
				"Tags": ["Honeypot", "Data"],
				"SW": ["Cowrie"],     
			}
			],
		"Attach": [{ "sessionid": sessionid, "url": url, "outfile": outfile, "smart": url }]
	}

	event = w3u.IDEA_fill_addresses(event, src_ip, dst_ip, aanonymised, aanonymised_net)	
	
	return event


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



con = my.connect( host=aconfig['dbhost'], user=aconfig['dbuser'], passwd=aconfig['dbpass'],
       		  db=aconfig['dbname'], port=aconfig['dbport'], cursorclass=mycursors.DictCursor)
crs = con.cursor()
events = []

#kippo vs cowrie
#cowrie/core/dblog.py:    def nowUnix(self):
#cowrie/core/dblog.py-        """return the current UTC time as an UNIX timestamp"""
#cowrie/core/dblog.py-        return int(time.time())
#kippo/core/dblog.py:    def nowUnix(self):
#kippo/core/dblog.py-        """return the current UTC time as an UNIX timestamp"""
#kippo/core/dblog.py-        return int(time.mktime(time.gmtime()[:-1] + (-1,)))
# k sozalenju 
# >>> int(time.mktime(time.gmtime()[:-1] + (-1,)))-int(time.time()) != 0

#success login
query =  "SELECT UNIX_TIMESTAMP(CONVERT_TZ(a.timestamp, @@global.time_zone, '+00:00')) as timestamp, s.ip as sourceip, sn.ip as sensor, a.session as sessionid, a.username as username, a.password as password \
	FROM auth a JOIN sessions s ON s.id=a.session JOIN sensors sn ON s.sensor=sn.id \
	WHERE a.success=1 AND CONVERT_TZ(a.timestamp, @@global.time_zone, '+00:00') > DATE_SUB(UTC_TIMESTAMP(), INTERVAL + %s SECOND) \
	ORDER BY a.timestamp ASC;"

crs.execute(query, (awin,))
rows = crs.fetchall()
for row in rows:
	a = gen_event_idea_cowrie_auth(
		detect_time = format_timestamp(row['timestamp']), 
		src_ip = row['sourceip'], 
		dst_ip = row['sensor'],
		
		username = row['username'],
		password = row['password'],
		sessionid = row['sessionid']
	)

	events.append(a)

#ttylog+iinput reporter
query =  "SELECT UNIX_TIMESTAMP(CONVERT_TZ(s.starttime, @@global.time_zone, '+00:00')) as starttime, s.ip as sourceip, sn.ip as sensor, t.session as sessionid \
          FROM ttylog t JOIN sessions s ON s.id=t.session JOIN sensors sn ON s.sensor=sn.id \
          WHERE CONVERT_TZ(s.starttime, @@global.time_zone, '+00:00') > DATE_SUB(UTC_TIMESTAMP(), INTERVAL + %s SECOND) \
          ORDER BY s.starttime ASC;"

crs.execute(query, (awin,))
rows = crs.fetchall()
for row in rows:
	a = gen_event_idea_ttylog(
		detect_time = format_timestamp(row['timestamp']), 
		conn_count = 1, 
		src_ip = row['sourceip'], 
		dst_ip = row['sensor'],

		sessionid = row['sessionid'],
		ttylog = get_ttylog(row['sessionid']),
		iinput = get_iinput(row['sessionid'])
	)	
	
	events.append(a)


#download
query =  "SELECT UNIX_TIMESTAMP(CONVERT_TZ(s.starttime, @@global.time_zone, '+00:00')) as starttime, s.ip as sourceip, sn.ip as sensor, d.session as sessionid, d.url as url, d.outfile as ofile \
	FROM downloads d JOIN sessions s ON s.id=d.session JOIN sensors sn ON s.sensor=sn.id \
	WHERE CONVERT_TZ(s.starttime, @@global.time_zone, '+00:00') > DATE_SUB(UTC_TIMESTAMP(), INTERVAL + %s SECOND) \
	ORDER BY s.starttime ASC;"

crs.execute(query, (awin,))
rows = crs.fetchall()
for row in rows:
	a = gen_event_idea_download(
		detect_time = format_timestamp(row['timestamp']), 
		conn_count = 1, 
		src_ip = row['sourceip'], 
		dst_ip = row['sensor'],

		sessionid = row['sessionid'],
		url = row['url'],
		outfile = row['ofile']
	)
	
	events.append(a)


print "=== Sending ==="
start = time()
ret = wclient.sendEvents(events)

if 'saved' in ret:
	wclient.logger.info("%d event(s) successfully delivered." % ret['saved'])

print "Time: %f" % (time() - start)



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

import MySQLdb as my
import MySQLdb.cursors as mycursors

import tempfile
import subprocess

DEFAULT_ACONFIG = 'warden_client-kippo.cfg'
DEFAULT_WCONFIG = 'warden_client.cfg'
DEFAULT_NAME = 'org.example.warden.test'
DEFAULT_AWIN = 5
DEFAULT_ANONYMISED = 'no'
DEFAULT_TARGET_NET = '0.0.0.0/0'

def anonymise(event, anonymised, target_net):
  if anonymised != 'omit':
    if anonymised == 'yes':
      event['Target'][0]['Anonymised'] = True
      event['Target'][0][af] = [target_net]
    else:
      event['Target'][0][af] = [dst_ip]

  return event


def gen_event_idea_auth(client_name, detect_time, conn_count, src_ip, dst_ip, anonymised, target_net, username, password, sessionid):

  event = {
     "Format": "IDEA0",
     "ID": str(uuid4()),
     "DetectTime": detect_time,
     "Category": ["Intrusion"],
     "Note": "SSH successfull attempt",
     "ConnCount": conn_count,
     "Source": [{}],
     "Target": [
        {
           "Proto": ["tcp", "ssh"],
           "Port" : [22]
        }
     ],
     "Node": [
        {
           "Name": client_name,
           "Tags": ["Honeypot", "Connection", "Auth"],
           "SW": ["Kippo"],
        }
     ],
     "Attach": [
       {
        "sessionid": sessionid,
	"username": username,
        "password": password
	}
     ]
  }
  af = "IP4" if not ':' in src_ip else "IP6"
  event['Source'][0][af] = [src_ip]
  event = anonymise(event, anonymised, target_net)
  
  return event


def gen_event_idea_ttylog(client_name, detect_time, conn_count, src_ip, dst_ip, anonymised, target_net, sessionid, ttylog):

  event = {
     "Format": "IDEA0",
     "ID": str(uuid4()),
     "DetectTime": detect_time,
     "Category": ["Malware.Virus"],
     "Note": "Kippo ttylog",
     "ConnCount": conn_count,
     "Source": [{}],
     "Target": [
        {
           "Proto": ["tcp", "ssh"],
           "Port" : [22]
        }
     ],
     "Node": [
        {
           "Name": client_name,
           "Tags": ["Honeypot", "Data"],
           "SW": ["Kippo"],
        }
     ],
     "Attach": [
       {
        "sessionid": sessionid,
        "ttylog": ttylog
	}
     ]
  }

  af = "IP4" if not ':' in src_ip else "IP6"
  event['Source'][0][af] = [src_ip]

  event = anonymise(event, anonymised, target_net)
  
  return event

def gen_event_idea_download(client_name, detect_time, conn_count, src_ip, dst_ip, anonymised, target_net, sessionid, url, output):

  event = {
     "Format": "IDEA0",
     "ID": str(uuid4()),
     "DetectTime": detect_time,
     "Category": ["Other"],
     "Note": "Kippo download",
     "ConnCount": conn_count,
     "Source": [{}],
     "Target": [
        {
           "Proto": ["tcp", "ssh"],
           "Port" : [22]
        }
     ],
     "Node": [
        {
           "Name": client_name,
           "Tags": ["Honeypot", "Data"],
           "SW": ["Kippo"],
        }
     ],
     "Attach": [
       {
        "sessionid": sessionid,
        "url": url,
        "output": output,
	}
     ]
  }
  af = "IP4" if not ':' in src_ip else "IP6"
  event['Source'][0][af] = [src_ip]
  event = anonymise(event, anonymised, target_net)
  
  return event




def gen_event_idea_download(client_name, detect_time, conn_count, src_ip, dst_ip, anonymised, target_net, sessionid, url, outfile):

  event = {
     "Format": "IDEA0",
     "ID": str(uuid4()),
     "DetectTime": detect_time,
     #"WinStartTime": win_start_time,
     #"WinEndTime": win_end_time,
     "Category": ["Other"],
     "Note": "Kippo download",
     "ConnCount": conn_count,
     "Source": [{}],
     "Target": [
        {
           "Proto": ["tcp", "ssh"],
           "Port" : [22]
        }
     ],
     "Node": [
        {
           "Name": client_name,
           "Tags": ["Honeypot", "Data"],
           "SW": ["Kippo"],
           #"AggrWin": strftime("%H:%M:%S", gmtime(aggr_win))
        }
     ],
     "Attach": [
       {
        "sessionid": sessionid,
        "url": url,
	"outfile": outfile
	}
     ]
  }
  af = "IP4" if not ':' in src_ip else "IP6"
  event['Source'][0][af] = [src_ip]
  event = anonymise(event, anonymised, target_net)
  
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



  #reporter
  con = my.connect( host=aconfig['dbhost'], user=aconfig['dbuser'], passwd=aconfig['dbpass'],
                    db=aconfig['dbname'], port=aconfig['dbport'], cursorclass=mycursors.DictCursor)
  
  crs = con.cursor()

  events = []






  query =  "SELECT UNIX_TIMESTAMP(CONVERT_TZ(s.starttime, '+00:00', @@global.time_zone)) as starttime, s.ip as sourceip, sn.ip as sensor, a.session as sessionid, a.username as username, a.password as password \
		FROM auth a JOIN sessions s ON s.id=a.session JOIN sensors sn ON s.sensor=sn.id \
		WHERE a.success=1 AND a.timestamp > DATE_SUB(UTC_TIMESTAMP(), INTERVAL + %s SECOND) \
		ORDER BY a.timestamp ASC;"
  crs.execute(query, awin)
  rows = crs.fetchall()
  for row in rows:
    #print json.dumps(row)
    dtime = format_timestamp(row['starttime'])
    a = gen_event_idea_auth(
		client_name = aname, 
		detect_time = dtime, 
		conn_count = 1, 
		src_ip = row['sourceip'], 
		dst_ip = row['sensor'],
		#aggr_win = 0,
		anonymised = aanonymised, 
		target_net = atargetnet,
		username = row['username'],
		password = row['password'],
		sessionid = row['sessionid']
	)
    #print json.dumps(a)
    events.append(a)





  query =  "SELECT UNIX_TIMESTAMP(CONVERT_TZ(s.starttime, '+00:00', @@global.time_zone)) as starttime, s.ip as sourceip, sn.ip as sensor, t.session as sessionid, t.ttylog as ttylog \
		FROM ttylog t JOIN sessions s ON s.id=t.session JOIN sensors sn ON s.sensor=sn.id \
		WHERE s.starttime > DATE_SUB(UTC_TIMESTAMP(), INTERVAL + %s SECOND) \
		ORDER BY s.starttime ASC;"
  crs.execute(query, awin)
  rows = crs.fetchall()
  for row in rows:
    try:
      tf = tempfile.NamedTemporaryFile(delete=False)
      with open(tf.name, 'w') as f:
        f.write(row['ttylog'])
      row['ttylog'] = subprocess.check_output(["/usr/bin/python", "/opt/kippo/utils/playlog.py", "-m0", tf.name])
    finally:
      os.remove(tf.name)
    
    #print json.dumps(row)
    dtime = format_timestamp(row['starttime'])
    a = gen_event_idea_ttylog(
		client_name = aname, 
		detect_time = dtime, 
		conn_count = 1, 
		src_ip = row['sourceip'], 
		dst_ip = row['sensor'],
		#aggr_win = 0,
		anonymised = aanonymised, 
		target_net = atargetnet,
		sessionid = row['sessionid'],
		ttylog = row['ttylog']
	)
    #print json.dumps(a)
    events.append(a)





  query =  "SELECT UNIX_TIMESTAMP(CONVERT_TZ(s.starttime, '+00:00', @@global.time_zone)) as starttime, s.ip as sourceip, sn.ip as sensor, d.session as sessionid, d.url as url, d.outfile as ofile \
		FROM downloads d JOIN sessions s ON s.id=d.session JOIN sensors sn ON s.sensor=sn.id \
		WHERE s.starttime > DATE_SUB(UTC_TIMESTAMP(), INTERVAL + %s SECOND) \
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
		#aggr_win = 0,
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
  
  if ret:
    wclient.logger.info("%d event(s) successfully delivered." % len(rows))

  print "Time: %f" % (time() - start)


if __name__ == "__main__":
    main()

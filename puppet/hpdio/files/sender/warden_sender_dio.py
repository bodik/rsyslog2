#!/usr/bin/python
# -*- coding: utf-8 -*-
#
# Copyright (C) 2011-2015 Cesnet z.s.p.o
# Use of this source is governed by a 3-clause BSD-style license, see LICENSE file.

from warden_client import Client, Error, read_cfg, format_timestamp
import json
import string
import urllib
from time import time, gmtime, strftime, sleep
from math import trunc
from uuid import uuid4
from os import path
import base64
import sqlite3
import sys
import re
import warden_utils_flab as w3u

aconfig = read_cfg('warden_client_dio.cfg')
wconfig = read_cfg('warden_client.cfg')
aclient_name = aconfig['name']
wconfig['name'] = aclient_name
aanonymised = aconfig['anonymised']
aanonymised_net  = aconfig['target_net']
aanonymised = aanonymised if (aanonymised_net != '0.0.0.0/0') or (aanonymised_net == 'omit') else '0.0.0.0/0'

awin = aconfig['awin'] * 60
abinpath = aconfig['binaries_path']
adbfile = aconfig['dbfile']
aconattempts = aconfig['con_attempts']
aretryinterval = aconfig['con_retry_interval']
areportbinaries = aconfig['report_binaries']

wconfig['secret'] = aconfig.get('secret', '')
wclient = Client(**wconfig)

def gen_attach_idea_smb(logger, report_binaries, binaries_path, filename, hashtype, hashdigest, vtpermalink, avref):
    
  refs = []
  attach = { 
         "Handle": 'att1',
         "FileName": [filename],
         "Type": ["Malware"],
         "Hash": ["%s:%s" % (hashtype, hashdigest)],
      }
  
  if vtpermalink is not None:
    refs.append('url:' + vtpermalink)
  
  if avref is not None:
    refs.extend(avref.split(';'))
  
  if refs:
    refs = [urllib.quote(ref, safe=':') for ref in refs]
    refs = list(set(refs))
    attach['Ref'] = refs

  if report_binaries == 'true':
    try:
      fpath = path.join(binaries_path, hashdigest)
      with open(fpath, "r") as f:
        fdata = f.read()
        attach['ContentType'] = 'application/octet-stream'
        attach['ContentEncoding'] = 'base64'
        attach['Size'] = len(fdata)
        attach['Content'] = base64.b64encode(fdata)
    except (IOError) as e:
      logger.info("Reading id file \"%s\" with malware failed, information will not be attached." % (fpath))

  return attach

def gen_attach_idea_mysql(logger, mysql_query):
  
  attach = {} 
  attach["Handle"] = 'att1'
  attach["Type"] = ["Malware"]
  attach['ContentType'] = 'text/plain'
  attach['Size'] = len(mysql_query)
  attach['Content'] = mysql_query

  return attach

def gen_event_idea_dio(logger, binaries_path, report_binaries, client_name, anonymised, target_net, detect_time, win_start_time, win_end_time, aggr_win, data):

  category = []
  event = {
     "Format": "IDEA0",
     "ID": str(uuid4()),
     "DetectTime": detect_time,
     "WinStartTime": win_start_time,
     "WinEndTime": win_end_time,
     "ConnCount": data['attack_scale'],
     "Source": [{}],
     "Target": [{}],
     "Node": [
        {
           "Name": client_name,
           "Type": ["Connection","Honeypot","Recon"],
           "Tags": ["Connection","Honeypot","Recon"],
           "SW": ["Dionaea"],
           "AggrWin": strftime("%H:%M:%S", gmtime(aggr_win))
        }
     ]
  }

  # Save TCP/UDP proto
  proto = [data['proto']]

  # smbd allows save malware
  if data['service'] == 'smbd' and data['download_md5_hash'] is not None:
    category.append('Attempt.Exploit')
    category.append('Malware')
    proto.append('smb')

    event['Source'][0]['URL'] = [data['download_url']]
    filename = data['download_url'].split('/')[-1]

    if filename != '' and data['download_md5_hash'] != '':
      # Generate "SMB Attach" part of IDEA
      a = gen_attach_idea_smb(logger, report_binaries, binaries_path, filename, "md5", data['download_md5_hash'], data['virustotal_permalink'], data['scan_result'])
    
      event['Source'][0]['AttachHand'] = ['att1']
      event['Attach'] = [a]
  
  if data['service'] == 'mysqld':
    #Clean exported data 
    mysql_data = re.sub("select @@version_comment limit 1,?", "", data['mysql_query']) 
    if mysql_data != "":
    	# Generate "MySQL Attach" part of IDEA
    	a = gen_attach_idea_mysql(logger, mysql_data)

	category.append('Attempt.Exploit')
	proto.append('mysql')
    	event['Source'][0]['AttachHand'] = ['att1']
    	event['Attach'] = [a]
	
  event['Source'][0]['Port']  = [data['src_port']]
  event['Target'][0]['Port']  = [data['dst_port']]
  event['Target'][0]['Proto'] = proto

  w3u.IDEA_fill_addresses(event, data['src_ip'], data['dst_ip'], aanonymised, aanonymised_net)
  

  # Add default category
  if not category:
  	category.append('Recon.Scanning')
  
  event['Category'] = category

  return event

def main():

  con = sqlite3.connect(adbfile)
  con.row_factory = sqlite3.Row
  crs = con.cursor()

  events = []
 
  query = "SELECT c.connection_timestamp AS timestamp, c.remote_host AS src_ip, c.remote_port AS src_port, c.connection_transport AS proto, \
            c.local_host AS dst_ip, c.local_port AS dst_port, COUNT(c.connection) as attack_scale, c.connection_protocol AS service, d.download_url, d.download_md5_hash, \
            v.virustotal_permalink, GROUP_CONCAT('urn:' || vt.virustotalscan_scanner || ':' || vt.virustotalscan_result,';') AS scan_result, \
            group_concat(mca.mysql_command_arg_data) as mysql_query \
            FROM connections AS c LEFT JOIN downloads AS d ON c.connection = d.connection \
            LEFT JOIN virustotals AS v ON d.download_md5_hash = v.virustotal_md5_hash \
            LEFT JOIN virustotalscans vt ON v.virustotal = vt.virustotal \
            LEFT JOIN mysql_commands mc ON c.connection = mc.connection  \
            LEFT JOIN mysql_command_args mca ON mc.mysql_command = mca.mysql_command \
            WHERE datetime(connection_timestamp,'unixepoch') > datetime('now','-%d seconds') AND c.remote_host != '' \
            GROUP BY c.remote_host, c.local_port ORDER BY c.connection_timestamp ASC;" % (awin)

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
    dtime = format_timestamp(row['timestamp'])
    events.append(gen_event_idea_dio(logger = wclient.logger, binaries_path = abinpath, report_binaries = areportbinaries, client_name = aclient_name, anonymised = aanonymised, target_net = aanonymised_net, detect_time = dtime, win_start_time = stime, win_end_time = etime, aggr_win = awin, data = row))
      
  print "=== Sending ==="
  start = time()

  ret = wclient.sendEvents(events)
  
  if 'saved' in ret:
    wclient.logger.info("%d event(s) successfully delivered." % ret['saved'])
  
  print "Time: %f" % (time() - start)


if __name__ == "__main__":
    main()

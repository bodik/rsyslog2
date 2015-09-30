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

DEFAULT_ACONFIG = 'warden_client-dio.cfg'
DEFAULT_WCONFIG = 'warden_client.cfg'
DEFAULT_BINPATH = '/opt/dionaea/var/dionaea/binaries'
DEFAULT_DBFILE  = '/opt/dionea/var/dionea/logsql.sqlite'
DEFAULT_NAME = 'org.example.warden.test'
DEFAULT_REPORT_BINARIES = 'false'
DEFAULT_AWIN = 5
DEFAULT_CON_ATTEMPTS = 3
DEFAULT_CON_RETRY_INTERVAL = 5
DEFAULT_ATTACH_NAME = 'att1'
DEFAULT_HASHTYPE = 'md5'
DEFAULT_CONTENT_TYPE = 'application/octet-stream'
DEFAULT_CONTENT_ENCODING = 'base64'
DEFAULT_ANONYMISED = 'no'
DEFAULT_TARGET_NET = '0.0.0.0/0'
DEFAULT_SECRET = ''


def gen_attach_idea(logger, report_binaries, binaries_path, filename, hashtype, hashdigest, vtpermalink, avref):
    
  refs = []
  attach = { 
         "Handle": DEFAULT_ATTACH_NAME,
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
        attach['ContentType'] = DEFAULT_CONTENT_TYPE
        attach['ContentEncoding'] = DEFAULT_CONTENT_ENCODING
        attach['Size'] = len(fdata)
        attach['Content'] = base64.b64encode(fdata)
    except (IOError) as e:
      logger.info("Reading id file \"%s\" with malware failed, information will not be attached." % (fpath))

  return attach

def gen_event_idea(logger, binaries_path, report_binaries, client_name, anonymised, target_net, detect_time, win_start_time, win_end_time, aggr_win, data):

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
           "Tags": ["Connection","Honeypot","Recon"],
           "SW": ["Dionaea"],
           "AggrWin": strftime("%H:%M:%S", gmtime(aggr_win))
        }
     ]
  }

  # Determine IP address family
  af = "IP4" if not ':' in data['src_ip'] else "IP6"
  
  # Extract & save proto and service name
  proto = [data['proto']]

  if data['service'] in ['mysql', 'mssql']:
    proto.append(data['service'])
  elif data['service'] in ['httpd', 'smbd']:
    proto.append(data['service'][:-1])

  # Choose correct category
  if data['service'] != 'pcap':
    category.append('Attempt.Exploit')
  else:
    category.append('Recon.Scanning')

  # smbd allows save malware
  if data['service'] == 'smbd' and data['download_md5_hash'] is not None:
    category.append('Malware')
    event['Source'][0]['URL'] = [data['download_url']]
    filename = data['download_url'].split('/')[-1]

    if filename != '' and data['download_md5_hash'] != '':
      # Generate "Attach" part of IDEA
      a = gen_attach_idea(logger, report_binaries, binaries_path, filename, DEFAULT_HASHTYPE, data['download_md5_hash'], data['virustotal_permalink'], data['scan_result'])
    
      event['Source'][0]['AttachHand'] = [DEFAULT_ATTACH_NAME]
      event['Attach'] = [a]


  event['Source'][0][af]      = [data['src_ip']]
  event['Source'][0]['Port']  = [data['src_port']]

  if anonymised != 'omit':
    if anonymised == 'yes':
      event['Target'][0]['Anonymised'] = True
      event['Target'][0][af] = [target_net]
    else:
      event['Target'][0][af] = [data['dst_ip']]

  event['Target'][0]['Port']  = [data['dst_port']]
  event['Target'][0]['Proto'] = proto

  event['Category'] = category

  return event

def main():
  aconfig = read_cfg(DEFAULT_ACONFIG)
  wconfig = read_cfg(aconfig.get('warden', DEFAULT_WCONFIG))
  
  aname = aconfig.get('name', DEFAULT_NAME)
  wconfig['name'] = aname   

  asecret = aconfig.get('secret', DEFAULT_SECRET)
  if asecret:
    wconfig['secret'] = asecret
  
  wclient = Client(**wconfig)

  awin = aconfig.get('awin', DEFAULT_AWIN) * 60
  abinpath = aconfig.get('binaries_path', DEFAULT_BINPATH)
  adbfile = aconfig.get('dbfile', DEFAULT_DBFILE)
  aconattempts = aconfig.get('con_attempts', DEFAULT_CON_ATTEMPTS)
  aretryinterval = aconfig.get('con_retry_interval', DEFAULT_CON_RETRY_INTERVAL)
  areportbinaries = aconfig.get('report_binaries', DEFAULT_REPORT_BINARIES)
  
  aanonymised = aconfig.get('anonymised', DEFAULT_ANONYMISED)
  if aanonymised not in ['no', 'yes', 'omit']:
    wclient.logger.error("Configuration error: anonymised: '%s' - possible typo? use 'no', 'yes' or 'omit'" % aanonymised)
    sys.exit(2)

  atargetnet  = aconfig.get('target_net', DEFAULT_TARGET_NET)
  aanonymised = aanonymised if (atargetnet != DEFAULT_TARGET_NET) or (aanonymised == 'omit') else DEFAULT_ANONYMISED



  con = sqlite3.connect(adbfile)
  con.row_factory = sqlite3.Row
  crs = con.cursor()

  events = []
  
  query =  "SELECT c.connection_timestamp AS timestamp, c.remote_host AS src_ip, c.remote_port AS src_port, c.connection_transport AS proto, \
            c.local_host AS dst_ip, c.local_port AS dst_port, COUNT(c.connection) as attack_scale, c.connection_protocol AS service, d.download_url, d.download_md5_hash, \
            v.virustotal_permalink, GROUP_CONCAT('urn:' || vt.virustotalscan_scanner || ':' || vt.virustotalscan_result,';') AS scan_result \
            FROM connections AS c LEFT JOIN downloads AS d ON c.connection = d.connection \
            LEFT JOIN virustotals AS v ON d.download_md5_hash = v.virustotal_md5_hash \
            LEFT JOIN virustotalscans vt ON v.virustotal = vt.virustotal \
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
    events.append(gen_event_idea(logger = wclient.logger, binaries_path = abinpath, report_binaries = areportbinaries, client_name = aname, anonymised = aanonymised, target_net = atargetnet, detect_time = dtime, win_start_time = stime, win_end_time = etime, aggr_win = awin, data = row))
      
  print "=== Sending ==="
  start = time()
  ret = wclient.sendEvents(events)
  
  if ret:
    wclient.logger.info("%d event(s) successfully delivered." % len(rows))

  print "Time: %f" % (time() - start)


if __name__ == "__main__":
    main()

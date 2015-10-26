#!/usr/bin/python
# -*- coding: utf-8 -*-
#
# Copyright (C) 2011-2015 Cesnet z.s.p.o
# Use of this source is governed by a 3-clause BSD-style license, see LICENSE file.

from warden_client import Client, Error, read_cfg, format_timestamp
import json
import string
from time import time, gmtime, strftime
from math import trunc
from uuid import uuid4
from os import path
import sys

import MySQLdb as my
import MySQLdb.cursors as mycursors

DEFAULT_ACONFIG = 'warden_client-kippo.cfg'
DEFAULT_WCONFIG = 'warden_client.cfg'
DEFAULT_NAME = 'org.example.warden.test'
DEFAULT_AWIN = 5
DEFAULT_ANONYMISED = 'no'
DEFAULT_TARGET_NET = '0.0.0.0/0'


def gen_event_idea(client_name, detect_time, win_start_time, win_end_time, conn_count, src_ip, dst_ip, aggr_win, anonymised, target_net):

  event = {
     "Format": "IDEA0",
     "ID": str(uuid4()),
     "DetectTime": detect_time,
     "WinStartTime": win_start_time,
     "WinEndTime": win_end_time,
     "Category": ["Attempt.Login"],
     "Note": "SSH login attempt",
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
           "Tags": ["Connection","Honeypot","Recon"],
           "SW": ["Cowrie"],
           "AggrWin": strftime("%H:%M:%S", gmtime(aggr_win))
        }
     ]
  }

  af = "IP4" if not ':' in src_ip else "IP6"
  event['Source'][0][af] = [src_ip]

  if anonymised != 'omit':
    if anonymised == 'yes':
      event['Target'][0]['Anonymised'] = True
      event['Target'][0][af] = [target_net]
    else:
      event['Target'][0][af] = [dst_ip]
  
  return event

def main():
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
  query =  "SELECT UNIX_TIMESTAMP(CONVERT_TZ(s.starttime, @@global.time_zone, '+00:00')) as starttime, s.ip, COUNT(s.id) as attack_scale, sn.ip as sensor \
            FROM sessions s \
            LEFT JOIN sensors sn ON s.sensor=sn.id \
            WHERE CONVERT_TZ(s.starttime, @@global.time_zone, '+00:00') > DATE_SUB(UTC_TIMESTAMP(), INTERVAL + %s SECOND) \
            GROUP BY s.ip ORDER BY s.starttime ASC;"

  crs.execute(query, awin)
  rows = crs.fetchall()
  for row in rows:
    dtime = format_timestamp(row['starttime'])
    etime = format_timestamp(time())
    stime = format_timestamp(time() - awin)
    events.append(gen_event_idea(client_name = aname, detect_time = dtime, win_start_time = stime, win_end_time = etime, conn_count = row['attack_scale'], src_ip = row['ip'], dst_ip = row['sensor'], aggr_win = awin, anonymised = aanonymised, target_net = atargetnet))
      
  print "=== Sending ==="
  start = time()
  ret = wclient.sendEvents(events)
  
  if ret:
    wclient.logger.info("%d event(s) successfully delivered." % len(rows))

  print "Time: %f" % (time() - start)


if __name__ == "__main__":
    main()

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

import MySQLdb as my
import MySQLdb.cursors as mycursors

DEFAULT_ACONFIG = 'warden_client-kippo.cfg'
DEFAULT_WCONFIG = 'warden_client.cfg'
DEFAULT_NAME = 'org.example.warden.test'
DEFAULT_AWIN = 5


def gen_event_idea(client_name, detect_time, win_start_time, win_end_time, conn_count, src_ip4, dst_ip4, aggr_win):

  event = {
     "Format": "IDEA0",
     "ID": str(uuid4()),
     "DetectTime": detect_time,
     "WinStartTime": win_start_time,
     "WinEndTime": win_end_time,
     "Category": ["Attempt.Login"],
     "Note": "SSH login attempt",
     "ConnCount": conn_count,
     "Source": [
        { 
          "IP4": [src_ip4],
        }
     ],
     "Target": [
        {
           "IP4": [dst_ip4],
           "Proto": ["tcp", "ssh"],
           "Port" : [22]
        }
     ],
     "Node": [
        {
           "Name": client_name,
           "Tags": ["Connection","Honeypot","Recon"],
           "SW": ["Kippo"],
           "AggrWin": strftime("%H:%M:%S", gmtime(aggr_win))
        }
     ]
  }

  return event

def main():
  aconfig = read_cfg(DEFAULT_ACONFIG)
  wconfig = read_cfg(aconfig.get('warden', DEFAULT_WCONFIG))
  
  aname = aconfig.get('name', DEFAULT_NAME)
  awin = aconfig.get('awin', DEFAULT_AWIN) * 60
  wconfig['name'] = aname

  wclient = Client(**wconfig)   

  con = my.connect( host=aconfig['dbhost'], user=aconfig['dbuser'], passwd=aconfig['dbpass'],
                    db=aconfig['dbname'], port=aconfig['dbport'], cursorclass=mycursors.DictCursor)
  
  crs = con.cursor()

  events = []
  query =  "SELECT UNIX_TIMESTAMP(s.starttime) as starttime, s.ip, COUNT(s.id) as attack_scale, sn.ip as sensor \
            FROM sessions s \
            LEFT JOIN sensors sn ON s.sensor=sn.id \
            WHERE s.starttime > DATE_SUB(UTC_TIMESTAMP(), INTERVAL + %s SECOND) \
            GROUP BY s.ip ORDER BY s.starttime ASC;"

  crs.execute(query, awin)
  rows = crs.fetchall()
  for row in rows:
    dtime = format_timestamp(row['starttime'])
    etime = format_timestamp(time())
    stime = format_timestamp(time() - awin)
    events.append(gen_event_idea(client_name = aname, detect_time = dtime, win_start_time = stime, win_end_time = etime, conn_count = row['attack_scale'], src_ip4 = row['ip'], dst_ip4 = row['sensor'], aggr_win = awin))
      
  print "=== Sending ==="
  start = time()
  ret = wclient.sendEvents(events)
  
  if ret:
    wclient.logger.info("%d event(s) successfully delivered." % len(rows))

  print "Time: %f" % (time() - start)


if __name__ == "__main__":
    main()

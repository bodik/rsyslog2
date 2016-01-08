#!/usr/bin/python
# -*- coding: utf-8 -*-

from warden_client import Client, Error, read_cfg, format_timestamp
from time import time, gmtime, sleep
import pprint
import json
import os
import socket
import sys
import signal

DEFAULT_ACONFIG = 'warden_torediser.cfg'
DEFAULT_WCONFIG = 'warden_client.cfg'
DEFAULT_NAME = 'org.example.warden.torediser'

pp = pprint.PrettyPrinter(indent=4)



def handler(signum = None, frame = None):
	print 'warden_torediser shutting down...'
	sys.exit(0)

def fetch_and_send(wclient):

	#print "=== Server info ==="
	#info = wclient.getInfo()
	#print info
	#print "=== Getting events ==="

	start = time()
	ret = wclient.getEvents(count=1000)
	print "Time: %f, Got %i events" % ((time()-start), len(ret))
	try:
		sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
		sock.connect( (aconfig['rediser_server'], aconfig['rediser_server_warden_port']) )
		for e in ret:
			sock.sendall(json.dumps(e))
			sock.sendall("\n")
	except Exception as e:
		print "ERROR: while sending data to rediser", e
	finally:
		sock.shutdown(socket.SHUT_RDWR)
		sock.close()
	
	return len(ret)



if __name__ == "__main__":
	signal.signal(signal.SIGTERM , handler)
        if sys.stdout.name == '<stdout>':
                sys.stdout = os.fdopen(sys.stdout.fileno(), 'w', 0)
        if sys.stderr.name == '<stderr>':
                sys.stderr = os.fdopen(sys.stderr.fileno(), 'w', 0)

	aconfig = read_cfg(DEFAULT_ACONFIG)
	wconfig = read_cfg(aconfig.get('warden', DEFAULT_WCONFIG))
	aname = aconfig.get('name', DEFAULT_NAME)
	wconfig['name'] = aname
	wclient = Client(**wconfig)

	while True:
		try:
			#fetch until queue drain and have a rest for while
			while (fetch_and_send(wclient) != 0):
				pass
			sleep(60)
		except KeyboardInterrupt as e:
			break
		except Exception as e:
			print e
			#backoff
			sleep(1)
			pass


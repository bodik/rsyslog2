#!/usr/bin/python
# -*- coding: utf-8 -*-

from warden_client import Client, Error, read_cfg, format_timestamp
from time import time, gmtime
import pprint
import json
##from math import trunc
##from uuid import uuid4
##import string
##from os import path
##from random import randint, randrange, choice, random;
##from base64 import b64encode;

import socket
import sys

DEFAULT_ACONFIG = 'warden_2rediser.cfg'
DEFAULT_WCONFIG = 'warden_client.cfg'
DEFAULT_NAME = 'org.example.warden.2rediser'
pp = pprint.PrettyPrinter(indent=4)

def fetch_and_send():
	aconfig = read_cfg(DEFAULT_ACONFIG)
	wconfig = read_cfg(aconfig.get('warden', DEFAULT_WCONFIG))
	aname = aconfig.get('name', DEFAULT_NAME)
	wconfig['name'] = aname
	wclient = Client(**wconfig)

	#print "=== Server info ==="
	#info = wclient.getInfo()
	#print info
	#print "=== Getting events ==="

	start = time()
	ret = wclient.getEvents(count=1000)
	#print "Time: %f" % (time()-start)
	#print "Got %i events" % len(ret)
	try:
		sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
		sock.connect( (aconfig['rediser_server'], aconfig['rediser_server_warden_port']) )
		for e in ret:
			sock.sendall(json.dumps(e))
			sock.sendall("\n")
	finally:
		sock.close()

def main():
	fetch_and_send()

if __name__ == "__main__":
	main()

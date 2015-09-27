#!/usr/bin/python

#warden
from warden_client import Client, Error, read_cfg, format_timestamp
import json
import string
from time import time, gmtime, strftime
from math import trunc
from uuid import uuid4
import os
import sys


DEFAULT_ACONFIG = 'warden_client-ucho.cfg'
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

def gen_event_idea_ucho(client_name, detect_time, conn_count, src_ip, dst_ip, anonymised, target_net, 
	peer_proto, peer_port, ucho_port, data):

	event = {
		"Format": "IDEA0",
		"ID": str(uuid4()),
		"DetectTime": detect_time,
		"Category": ["Intrusion"],
		"Note": "Ucho event",
		"ConnCount": conn_count,
		"Source": [{ "Proto": [peer_proto], "Port": [peer_port] }],
		"Target": [{ "Proto": [peer_proto], "Port": [ucho_port] }],
		"Node": [
			{
				"Name": client_name,
				"Tags": ["Honeypot", "Connection"],
				"SW": ["Ucho"],
			}
		],
		"Attach": [{ "data": data }]
	}
	event = fill_addresses(event, src_ip, anonymised, target_net)
  
	return event

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





#ucho
from twisted.internet.protocol import Protocol, Factory
from twisted.internet import reactor
from twisted.internet.error import CannotListenError
import json
import socket

class Ucho(Protocol):
	def dump(self, src, length=16):
		FILTER=''.join([(len(repr(chr(x)))==3) and chr(x) or '.' for x in range(256)])
		N=0
		result=''
		while src:
			s,src = src[:length],src[length:]
			hexa = ' '.join(["%02X"%ord(x) for x in s])
			s = s.translate(FILTER)
			result += "%04X   %-*s   %s\n" % (N, length*3, hexa, s)
			N+=length
		return result

   	def connectionMade(self):
		self._peer = self.transport.getPeer()
		self._socket = self.transport.socket.getsockname()
		self._dtime = format_timestamp()
		self._data = []
		wclient.logger.debug("connected %s" % self._peer)

	def connectionLost(self, reason):
		wclient.logger.debug("disconnected %s" % self._peer)
		#print "DATA: %s" % self.dump( ''.join(self._data))
		a = gen_event_idea_ucho(
			client_name = aname, 
			detect_time = self._dtime,
			conn_count = 1, 
			anonymised = aanonymised, 
			target_net = atargetnet,

			peer_proto = self._peer.type.lower(),

			src_ip = self._peer.host, 
			peer_port = self._peer.port,

			ucho_port = self._socket[1],
			dst_ip = self._socket[0],

			data = self.dump( ''.join(self._data))
		)
		#print "DEBUG: %s" % json.dumps(a, indent=3)
		ret = wclient.sendEvents([a])
		if 'saved' in ret:
			wclient.logger.info("%d event(s) successfully delivered." % ret['saved'])
	
	def dataReceived(self, data):
		wclient.logger.debug("received from %s, len %d" % (self._peer, len(data)))
		self._data.append(data)
		#import pdb; pdb.set_trace()
		#print "DATA: ", self.dump(data)



#ucho
factory = Factory()
factory.protocol = Ucho

for i in range(aconfig.get('port_start', 9999), aconfig.get('port_end', 9999)):
	try:
		reactor.listenTCP(i, factory)
	except CannotListenError:
		pass
	
reactor.run()


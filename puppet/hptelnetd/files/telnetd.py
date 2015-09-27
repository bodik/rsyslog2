#!/usr/bin/python
#mbologna/telnetd_redacted/master/telnetd.py

#warden
from warden_client import Client, Error, read_cfg, format_timestamp
import json
import string
from time import time, gmtime, strftime
from math import trunc
from uuid import uuid4
import os
import sys

DEFAULT_ACONFIG = 'warden_client-telnetd.cfg'
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


def gen_event_idea_telnetd(client_name, detect_time, conn_count, src_ip, dst_ip, anonymised, target_net, 
	client_proto, client_port, server_port, data):

	event = {
		"Format": "IDEA0",
		"ID": str(uuid4()),
		"DetectTime": detect_time,
		"Category": ["Information.UnauthorizedAccess"],
		"Note": "telnetd event",
		"ConnCount": conn_count,
		"Source": [{ "Proto": [client_proto], "Port": [client_port] }],
		"Target": [{ "Proto": [client_proto], "Port": [server_port] }],
		"Node": [
			{
				"Name": client_name,
				"Tags": ["Honeypot", "Connection"],
				"SW": ["telnetd"],
			}
		],
		"Attach": [{ "data": hex_escape(data), "datalen": len(data) }]
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


def hexdump(src, length=16):
	FILTER=''.join([(len(repr(chr(x)))==3) and chr(x) or '.' for x in range(256)])
	N=0; result=''
	while src:
		s,src = src[:length],src[length:]
		hexa = ' '.join(["%02X"%ord(x) for x in s])
		s = s.translate(FILTER)
		result += "%04X   %-*s   %s\n" % (N, length*3, hexa, s)
		N+=length
	return result

import string
printable = string.ascii_letters + string.digits + string.punctuation + ' '
def hex_escape(s):
	return ''.join(c if c in printable else r'\x{0:02x}'.format(ord(c)) for c in s)







#telnetd
from twisted.internet import protocol, reactor, endpoints
import logging
import random


class Telnetd(protocol.Protocol):
	PROMPT = "/ # "
	LOGIN = "login: "
	PASSWORD = "password: "
	#login, password, prompt
	state = "login"
	counter = 0

	def dataReceived(self, data):
		if self.counter > 2:
			self.transport.loseConnection()

		data = data.strip()
		self._data.append(data)
		if self.state == "login":
			if data == "root":
				self.state="password"
				self.transport.write(Telnetd.PASSWORD)
			else:
				self.counter = self.counter+1
				self.transport.write(Telnetd.LOGIN)
			
		elif self.state == "password":
			if data == "root":
				self.state="prompt"
				self.transport.write(Telnetd.PROMPT)
			else:
				self.counter = self.counter+1
				self.state="login"
				self.transport.write(Telnetd.LOGIN)
		else:
			self.doPrompt(data)


	def doPrompt(self, data):
        	data = data.strip()
		self._data.append(data)
		if data == "id":
			self.transport.write("uid=0(root) gid=0(root) groups=0(root)\n")
		elif data.split(" ")[0] == "uname":
			self.transport.write("Linux fc01 3.13.3-7-brocade #1 SMP x86_64 x86_64 Fabric OS\n") 
		else:
			if random.randrange(0, 2) == 0 and data != "":
				self.transport.write("ash: " +  data.split(" ")[0] + ": command not found\n")

		self.transport.write(Telnetd.PROMPT)

	def connectionMade(self):
		self._peer = self.transport.getPeer()
		self._socket = self.transport.socket.getsockname()
		self._dtime = format_timestamp()
		self._data = []
		wclient.logger.debug("connected %s" % self._peer)

		#self.transport.write(Telnetd.LOGIN)

	def connectionLost(self, reason):
		wclient.logger.debug("disconnected %s" % self._peer)
		#print "DATA: %s" % self.dump( ''.join(self._data))
		a = gen_event_idea_telnetd(
			client_name = aname, 
			detect_time = self._dtime,
			conn_count = 1, 
			anonymised = aanonymised, 
			target_net = atargetnet,

			client_proto = self._peer.type.lower(),
			src_ip = self._peer.host, 
			client_port = self._peer.port,
			server_port = self._socket[1],
			dst_ip = self._socket[0],
			data = '\n'.join(self._data)
		)
		#print "DEBUG: %s" % json.dumps(a, indent=3)
		ret = wclient.sendEvents([a])
		if 'saved' in ret:
			wclient.logger.info("%d event(s) successfully delivered." % ret['saved'])




class TelnetdFactory(protocol.Factory):
	def buildProtocol(self, addr):
        	return Telnetd()

endpoints.serverFromString(reactor, str(aconfig.get('twisted_port_spec'))).listen(TelnetdFactory())
reactor.run()


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


DEFAULT_ACONFIG = 'warden_client-uchoudp.cfg'
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

def get_ip_address(ifname):
    s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    #0x8915 - SIOCGIFADDR
    return socket.inet_ntoa(fcntl.ioctl(s.fileno(),0x8915,struct.pack('256s', ifname[:15]))[20:24])

def gen_event_idea_uchoudp(client_name, detect_time, conn_count, src_ip, dst_ip, anonymised, target_net, 
	peer_proto, peer_port, uchoudp_port, data):
	
	###print "DEBUG:", "AAA", data

	event = {
		"Format": "IDEA0",
		"ID": str(uuid4()),
		"DetectTime": detect_time,
		"Category": ["Intrusion"],
		"Note": "Ucho event",
		"ConnCount": conn_count,
		"Source": [{ "Proto": peer_proto, "Port": [peer_port] }],
		"Target": [{ "Proto": peer_proto, "Port": [uchoudp_port] }],
		"Node": [
			{
				"Name": client_name,
				"Tags": ["Honeypot", "Connection"],
				"SW": ["Uchoudp"],
			}
		],
		"Attach": [{ "data": hexdump(data), "datalen": len(data) }]
	}
	event = fill_addresses(event, src_ip, anonymised, target_net)
	event = proto_detection(event, data)
  
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


def proto_detection(event, data):
	try:
		if (161 in event["Target"][0]["Port"]) or (162 in event["Target"][0]["Port"]):
			parse = scapy.all.SNMP(data)
			event["Attach"][0]["datadecoded"] = repr(parse)
			event["Attach"][0]["smart"] = parse.community.val
			event["Source"][0]["Proto"] = event["Source"][0]["Proto"] + ["snmp"]
			event["Target"][0]["Proto"] = event["Target"][0]["Proto"] + ["snmp"]

		if 53 in event["Target"][0]["Port"]:
			parse = scapy.all.DNS(data)
			#import pdb; pdb.set_trace()
			event["Attach"][0]["datadecoded"] = repr(parse)
			event["Attach"][0]["smart"] = repr(parse.qd)
			event["Source"][0]["Proto"] = event["Source"][0]["Proto"] + ["dns"]
			event["Target"][0]["Proto"] = event["Target"][0]["Proto"] + ["dns"]
	
	except Exception as e:
		pass

	return event


#uchoudp
from twisted.internet.error import CannotListenError
from twisted.internet.protocol import DatagramProtocol
from twisted.internet import reactor
import socket, fcntl, struct, json, re

import scapy.all
from cStringIO import StringIO

class UchoUDP(DatagramProtocol):
    	def datagramReceived(self, data, (host, port)):

		if re.match("autotest.*", data):
			#import pdb; pdb.set_trace()
			self.transport.write(data, (host, port))

	#	import pdb; pdb.set_trace()
		wclient.logger.debug("received from %s:%s, len %d" % (host, port, len(data)))
   	
		a = gen_event_idea_uchoudp(
			client_name = aname, 
			detect_time = format_timestamp(),
			conn_count = 1, 
			anonymised = aanonymised, 
			target_net = atargetnet,

			peer_proto = [proto],

			src_ip = host, 
			peer_port = port,

			uchoudp_port = self.transport.socket.getsockname()[1],
			dst_ip = dst_ip,

			data = data
		)
		wclient.logger.debug("event %s" % json.dumps(a, indent=2))
		ret = wclient.sendEvents([a])
		if 'saved' in ret:
			wclient.logger.info("%d event(s) successfully delivered." % ret['saved'])

#uchoudp
proto = 'udp'
dst_ip = get_ip_address('eth0')
skipports = aconfig.get('port_skip', [])
wclient.logger.debug(skipports)

for i in range(aconfig.get('port_start', 9999), aconfig.get('port_end', 9999)):
	#skipt configured ports
	if i in skipports:
		continue

	#try to open the rest
	try:
		reactor.listenUDP(i, UchoUDP())
	except:
		pass	

reactor.run()


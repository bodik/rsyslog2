#!/usr/bin/python

from twisted.internet.error import CannotListenError
from twisted.internet.protocol import DatagramProtocol
from twisted.internet import reactor
from warden_client import read_cfg, format_timestamp
from time import time 
import re
import json
import string
import logging
import warden_utils_flab as w3u
import scapy.all

hconfig = read_cfg('uchoudp.cfg')
skipports = hconfig.get('port_skip', [])
logger = w3u.getLogger(hconfig['logfile'])

class UchoUDP(DatagramProtocol):
    
    proto = 'udp'
    dst_ip = '0.0.0.0'
    iface = 'eth0'
   
    def __init__(self):
	self.dst_ip = w3u.get_ip_address(self.iface)
   
    def datagramReceived(self, data, (host, port)):
	if re.match("autotest.*", data):
		self.transport.write(data, (host, port))

	else:
		data2log  = {
			 "detect_time" : format_timestamp(),
			 "proto"       : [self.proto],
			 "src_ip"      : host,
			 "src_port"    : port,
			 "dst_ip"      : self.dst_ip,
			 "dst_port"    : self.transport.socket.getsockname()[1],
			 "decoded"     : "",
			 "smart"       : "",
			 "data"        : w3u.hexdump(data),
		}

		data2log = self.proto_detection(data2log, data)
		
		logger.info(json.dumps(data2log))	

    def proto_detection(self, event, data):
         try:
		if event["dst_port"] in [161, 162]:
                        parse = scapy.all.SNMP(data)
                        event["decoded"] = repr(parse)
                        event["smart"] = parse.community.val
                        event["proto"] = event["proto"] + ["snmp"]

                if event["dst_port"] == 53:
                        parse = scapy.all.DNS(data)
                        event["decoded"] = repr(parse)
                        event["smart"] = repr(parse.qd)
                        event["proto"] = event["proto"] + ["dns"]
		
         except Exception as e:
                pass

         return event

def main():
	for i in range(hconfig.get('port_start', 9999), hconfig.get('port_end', 9999)):
		#skipt configured ports
		if i in skipports:
			continue
	
		#try to open the rest
		try:
			reactor.listenUDP(i, UchoUDP())
		except Exception as e:
			print e
			pass	

	reactor.run()

if __name__ == "__main__":
    main()


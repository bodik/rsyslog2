#!/usr/bin/python

from twisted.internet.protocol import Protocol, Factory
from twisted.internet import reactor
from warden_client import read_cfg, format_timestamp
import json, socket, re
import os
import sys
import logging
import w3utils_flab as w3u

hconfig = read_cfg('uchotcp.cfg')
skipports = hconfig.get('port_skip', [])
logger = w3u.getLogger(hconfig['logfile'])

class UchoTCP(Protocol):

   	def connectionMade(self):
		self._peer = self.transport.getPeer()
		self._proto = self._peer.type.lower()
		self._socket = self.transport.socket.getsockname()
		self._dtime = format_timestamp()
		self._data = []

	def connectionLost(self, reason):
		data = ''.join(self._data)
		data2log  = {
                         "detect_time" : self._dtime,
                         "proto"       : [self._proto],
                         "src_ip"      : self._peer.host,
                         "src_port"    : self._peer.port,
                         "dst_ip"      : self._socket[0],
                         "dst_port"    : self._socket[1],
			 "smart"       : "",
			 "decoded"     : "",
                         "data"        : w3u.hexdump(data),
                }

                data2log = self.proto_detection(data2log, data)
                logger.info(json.dumps(data2log))
	
	def dataReceived(self, data):
		self._data.append(data)

	def proto_detection(self, event, data):
		res = re.match("([A-Za-z]{3,20}) (.*) HTTP/", data)
		if res:
			event["smart"] = res.group(1)+" "+res.group(2)
			event["decoded"] = {}
			event["decoded"]["protocol"] = "http"
			event["decoded"]["method"] = res.group(1)
			event["decoded"]["uri"] = res.group(2)
			event["decoded"]["data"] = data
			event["proto"] = event["proto"] + ["http"]

		res = re.match("^(SSH-.*)\r\n", data)
		if res:
			event["smart"] = res.group(1)
			event["proto"] = event["proto"] + ["ssh"]

		return event

def main():

	factory = Factory()
	factory.protocol = UchoTCP

        for i in range(hconfig.get('port_start', 9999), hconfig.get('port_end', 9999)):
                #skipt configured ports
                if i in skipports:
                        continue

                #try to open the rest
                try:
                        reactor.listenTCP(i, factory)
                except Exception as e:
                        print e
                        pass

        reactor.run()

if __name__ == "__main__":
    main()

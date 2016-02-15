#!/usr/bin/python

from twisted.protocols.policies import TimeoutMixin
from twisted.internet.protocol import Protocol, Factory
from twisted.internet import reactor
from warden_client import read_cfg, format_timestamp
import json, socket, re
import os
import sys
import logging
import warden_utils_flab as w3u
import time
import struct
import uuid

hconfig 		= read_cfg('jdwpd.cfg')
logger 			= w3u.getLogger(hconfig['logfile'])

DEBUG 			= False

DEFAULT_PORT 		= 58000

HANDSHAKE               = "JDWP-Handshake"
AUTOTEST		= "AUTOTEST\n"

REQUEST_PACKET_TYPE     = 0x00
REPLY_PACKET_TYPE       = 0x80

NO_ERROR		= 0x00

EVENT_FIRE_INTERVAL	= 2

NODATA_TIMEOUT		= 2

HEADER_LENGTH		= 11

VERSION_SIG     	= (1, 1)
IDSIZES_SIG     	= (1, 7)
ALLCLASSES_SIG  	= (1, 3)
SUSPENDVM_SIG           = (1, 8)
ALLTHREADS_SIG  	= (1, 4)
RESUMEVM_SIG    	= (1, 9)
CREATESTRING_SIG 	= (1, 11)
FIELDS_SIG              = (2, 4)
METHODS_SIG     	= (2, 5)
GETVALUES_SIG           = (2, 6)
INVOKESTATICMETHOD_SIG  = (3, 3)
INVOKEMETHOD_SIG        = (9, 6)
THREADSTATUS_SIG	= (11, 4)
EVENTSET_SIG    	= (15, 1)
EVENTCLEAR_SIG  	= (15, 2)
AUTOTEST_SIG		= (15,15)

IDSIZES_RES 		=	'\x00\x00\x00\x08\x00\x00\x00\x08\x00\x00\x00\x08\x00\x00\x00\x08' \
				'\x00\x00\x00\x08'

				# Java Debug Wire Protocol (Reference Implementation) version 1.6
				# JVM Debug Interface version 1.2
				# JVM version 1.6.0_22 (OpenJDK 64-Bit Server VM, mixed mode, sharing)
				# 1.6.0_22 OpenJDK 64-Bit Server VM

VERSION_RES		=	'\x00\x00\x00\xa4\x4a\x61\x76\x61\x20\x44\x65\x62\x75\x67\x20\x57' \
				'\x69\x72\x65\x20\x50\x72\x6f\x74\x6f\x63\x6f\x6c\x20\x28\x52\x65' \
				'\x66\x65\x72\x65\x6e\x63\x65\x20\x49\x6d\x70\x6c\x65\x6d\x65\x6e' \
				'\x74\x61\x74\x69\x6f\x6e\x29\x20\x76\x65\x72\x73\x69\x6f\x6e\x20' \
				'\x31\x2e\x36\x0a\x4a\x56\x4d\x20\x44\x65\x62\x75\x67\x20\x49\x6e' \
				'\x74\x65\x72\x66\x61\x63\x65\x20\x76\x65\x72\x73\x69\x6f\x6e\x20' \
				'\x31\x2e\x32\x0a\x4a\x56\x4d\x20\x76\x65\x72\x73\x69\x6f\x6e\x20' \
				'\x31\x2e\x36\x2e\x30\x5f\x32\x32\x20\x28\x4f\x70\x65\x6e\x4a\x44' \
				'\x4b\x20\x36\x34\x2d\x42\x69\x74\x20\x53\x65\x72\x76\x65\x72\x20' \
				'\x56\x4d\x2c\x20\x6d\x69\x78\x65\x64\x20\x6d\x6f\x64\x65\x2c\x20' \
				'\x73\x68\x61\x72\x69\x6e\x67\x29\x00\x00\x00\x01\x00\x00\x00\x06' \
				'\x00\x00\x00\x08\x31\x2e\x36\x2e\x30\x5f\x32\x32\x00\x00\x00\x18' \
				'\x4f\x70\x65\x6e\x4a\x44\x4b\x20\x36\x34\x2d\x42\x69\x74\x20\x53' \
				'\x65\x72\x76\x65\x72\x20\x56\x4d'

				# Ljava/lang/Runtime;
				# Ljava/net/ServerSocket;
				# Ljava/lang/System;

ALLCLASSES_RES 		=	'\x00\x00\x00\x03\x01\x00\x00\x00\x00\x00\x00\x00\xb3\x00\x00\x00' \
				'\x13\x4c\x6a\x61\x76\x61\x2f\x6c\x61\x6e\x67\x2f\x52\x75\x6e\x74' \
				'\x69\x6d\x65\x3b\x00\x00\x00\x07' \
				'\x01\x00\x00\x00\x00\x00\x00\x04\xee\x00\x00\x00\x17\x4c\x6a\x61' \
				'\x76\x61\x2f\x6e\x65\x74\x2f\x53\x65\x72\x76\x65\x72\x53\x6f\x63' \
				'\x6b\x65\x74\x3b\x00\x00\x00\x07' \
				'\x01\x00\x00\x00\x00\x00\x00\x03\xc8\x00\x00\x00\x12\x4c\x6a\x61' \
				'\x76\x61\x2f\x6c\x61\x6e\x67\x2f\x53\x79\x73\x74\x65\x6d\x3b\x00' \
				'\x00\x00\x07'


ALLTHREADS_RES		= 	'\x00\x00\x00\x01\x00\x00\x00\x00\x00\x00\x06\xa2'

THREADSTATUS_RES	=	'\x00\x00\x00\x02\x00\x00\x00\x00'

METHOD_RUNTIME_REQ  	=	'\x00\x00\x00\x00\x00\x00\x00\xb3' 

				# getRuntime()Ljava/lang/Runtime;
				# exec(Ljava/lang/String;)Ljava/lang/Process;

METHOD_RUNTIME_RES	=   	'\x00\x00\x00\x02\x00\x00\x7f\xbc\xe8\x00\x11\x08\x00\x00\x00\x0a' \
				'\x67\x65\x74\x52\x75\x6e\x74\x69\x6d\x65\x00\x00\x00\x15\x28\x29' \
				'\x4c\x6a\x61\x76\x61\x2f\x6c\x61\x6e\x67\x2f\x52\x75\x6e\x74\x69' \
				'\x6d\x65\x3b\x00\x00\x00\x09' \
				'\x00\x00\x7f\xbc\xe8\x00\x11\x40\x00\x00\x00\x04\x65\x78\x65\x63' \
				'\x00\x00\x00\x27\x28\x4c\x6a\x61\x76\x61\x2f\x6c\x61\x6e\x67\x2f' \
				'\x53\x74\x72\x69\x6e\x67\x3b\x29\x4c\x6a\x61\x76\x61\x2f\x6c\x61' \
				'\x6e\x67\x2f\x50\x72\x6f\x63\x65\x73\x73\x3b\x00\x00\x00\x01'

METHOD_SACCEPT_REQ  	=	'\x00\x00\x00\x00\x00\x00\x04\xee'

				# accept()Ljava/net/Socket;

METHOD_SACCEPT_RES  	=   	'\x00\x00\x00\x01\x00\x00\x7f\xbc\xe8\x00\x12\xf0\x00\x00\x00\x06' \
				'\x61\x63\x63\x65\x70\x74\x00\x00\x00\x13\x28\x29\x4c\x6a\x61\x76' \
				'\x61\x2f\x6e\x65\x74\x2f\x53\x6f\x63\x6b\x65\x74\x3b\x00\x00\x00' \
				'\x01'

EVENTSET_RES		=	'\x00\x00\x00\x02'

EVENT_HIT_RES  		=   	'\x00\x00\x00\x36\x00\x00\x00\x02\x00\x40\x64\x02\x00\x00\x00\x01' \
				'\x02\x00\x00\x00\x02\x00\x00\x00\x00\x00\x00\x06\xa2\x01\x00\x00' \
				'\x00\x00\x00\x00\x04\xee\x00\x00\x7f\xbc\xe8\x00\x12\xf0\x00\x00' \
				'\x00\x00\x00\x00\x00\x00'

CREATESTRING_RES   	= 	'\x00\x00\x00\x00\x00\x00\x06\xa3'

INVOKESTATICMETHOD_RES 	=  	'\x4c\x00\x00\x00\x00\x00\x00\x06\xa4\x4c\x00\x00\x00\x00\x00\x00' \
				'\x00\x00'

INVOKEMETHOD_RES  	=   	'\x4c\x00\x00\x00\x00\x00\x00\x06\xa5\x4c\x00\x00\x00\x00\x00\x00' \
				'\x00\x00'

				# security Ljava/lang/Security/Manager

FIELDS_RES		=	'\x00\x00\x00\x01\x00\x00\x7f\xf0\x7c\x00\x63\x00\x00\x00\x00\x08' \
				'\x73\x65\x63\x75\x72\x69\x74\x79\x00\x00\x00\x1b\x4c\x6a\x61\x76' \
				'\x61\x2f\x6c\x61\x6e\x67\x2f\x53\x65\x63\x75\x72\x69\x74\x79\x4d' \
				'\x61\x6e\x61\x67\x65\x72\x3b\x00\x00\x00\x4a'

GETVALUES_RES		=	'\x00\x00\x00\x01\x4c\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00' 

NODATA		    	=	''


def toHex(data):
	return " ".join("{:02x}".format(ord(c)) for c in data)

def genId():
	return str(uuid.uuid4())[0:8]

class JDWPD(Protocol, TimeoutMixin):
	
	eventfired = False
	lastaction = None
	method     = "unknown"
	cstring    = ""
	
   	def connectionMade(self):
		self._peer = self.transport.getPeer()
	        self._srcip = self._peer.host
        	self._srcport = self._peer.port
		self._proto = self._peer.type.lower()
		self._socket = self.transport.socket.getsockname()
		self._dtime = format_timestamp()
		self._data = []
		self._sessionid = genId()

		self.lastaction = "CONNECTED"	
		print "Connection #%s made: %s" % (self._sessionid, self._srcip)
        	self.setTimeout(NODATA_TIMEOUT)

	def connectionLost(self, reason):
		self.setTimeout(None)
		print "Connection #%s closed: %s" % (self._sessionid, self._srcip)
		
		category = "Other"
        	if self.lastaction == "CONNECTED":
                	category = "Recon.Scanning"
        	elif self.lastaction == "BREAKPOINT":
                	category = "Attempt.Exploit"
		
		data = ''.join(self._data)
	        data2log  = {
			 "detect_time" : self._dtime,
			 "proto"       : self._proto,
			 "src_ip"      : self._srcip,
			 "src_port"    : self._srcport,
			 "dst_ip"      : self._socket[0],
			 "dst_port"    : self._socket[1],
			 "category"    : category,
			 "method"      : self.method,
			 "cstring"     : self.cstring,
			 "data"	       : w3u.hexdump(data)
        	}

	        logger.info(json.dumps(data2log))	
	
	def timeoutConnection(self):
		self.log("Timeout reached")
        	self.transport.abortConnection()

	def log(self, msg):
		print "Connection #%s - %s." % (self._sessionid, msg)

	def parsePacket(self, data):
		header = data[:HEADER_LENGTH]
		message = data[HEADER_LENGTH:]
	
		if(len(header) != HEADER_LENGTH):
			print self.log("Bad header length")
			return None

		ret = {}		
		try:
			pktlen, id, flag, cmd, cmdset = struct.unpack(">IIccc", header)
			ret['pktlen'] = pktlen
			ret['id'] = id
			ret['cmdsig'] = (ord(cmd), ord(cmdset))
			ret['message'] = message

		except:
			self.log("Bad packet format (can't unpack)")
			return None
		
		if(len(data) != pktlen):
			self.log("Connection #%s - Bad packet length")
			return None
			
		return ret		

	def createPacket(self, id, data = ""):
        	pktlen = len(data) + 11
        	pkt = struct.pack(">IIcH", pktlen, id, chr(REPLY_PACKET_TYPE), NO_ERROR)
        	pkt+= data

	        return pkt

	def sendData(self, id, data):
		pkt = self.createPacket(id, data)
		self.transport.socket.send(pkt)
		if(DEBUG):
			self.log("DATA OUT: %s" % (toHex(pkt)))

	def dataReceived(self, data):
		self.setTimeout(None)
		self._data.append(data)
				
		if(DEBUG):
			self.log("DATA IN: (%s)" % (toHex(data)))
	       	
		if(data.startswith(HANDSHAKE)):	
                        self.log("Request for handshake from %s" % (self._srcip))
                        self.log("Responding for HANDSHAKE")
			self.transport.socket.send(HANDSHAKE)
			data = data[len(HANDSHAKE):]
		
		if data:
			p = self.parsePacket(data)
			if (p is None):
				self.transport.loseConnection()
				return 

			cmdsig = p['cmdsig']
			id = p['id']
		
			if(cmdsig == IDSIZES_SIG):
				self.log("Responding for IDSIZES")
				self.sendData(id, IDSIZES_RES)
			
			elif(cmdsig == VERSION_SIG):
				self.log("Responding for VERSION")
				self.sendData(id, VERSION_RES)
			
			elif(cmdsig == ALLCLASSES_SIG):
				self.log("Responding for ALLCLASSES")
				self.sendData(id, ALLCLASSES_RES)
			
			elif(cmdsig == ALLTHREADS_SIG):
				self.log("Responding for ALLTHREADS")
				self.sendData(id, ALLTHREADS_RES)
				self.method = "msf-java_jdwp_debbuger"
			
			elif(cmdsig == THREADSTATUS_SIG):
				self.log("Responding for THREADSTATUS")
				self.sendData(id, THREADSTATUS_RES)
			
			elif(cmdsig == METHODS_SIG):
				if(p['message'] == METHOD_RUNTIME_REQ):
					self.log("Responding for METHOD_RUNTIME")
					self.sendData(id, METHOD_RUNTIME_RES)
				elif(p['message'] == METHOD_SACCEPT_REQ):
					self.log("Responding for METHOD SOCKET ACCEPT")
					self.sendData(id, METHOD_SACCEPT_RES)
			
			elif(cmdsig == FIELDS_SIG):
				self.log("Responding for FIELDS")
				self.sendData(id, FIELDS_RES)
			
			elif(cmdsig == GETVALUES_SIG):
				self.log("Responding for GETVALUES")
				self.sendData(id, GETVALUES_RES)
			
			elif(cmdsig == EVENTSET_SIG):
				self.log("Responding for BREAKPOINT")
				self.sendData(id, EVENTSET_RES)
				self.lastaction = "BREAKPOINT"
			
			elif(cmdsig == SUSPENDVM_SIG):
				self.log("Responding for SUSPENDVM")
				self.sendData(id, NODATA)
			
			elif(cmdsig == RESUMEVM_SIG):
				self.log("Responding for RESUME")
				self.sendData(id, NODATA)
		
				if(self.eventfired == False):
					time.sleep(EVENT_FIRE_INTERVAL)
					self.log("Sending 'EVENT FIRED' notification to client")
					self.transport.socket.send(EVENT_HIT_RES)
					self.eventfired = True
			
			elif(cmdsig == EVENTCLEAR_SIG):
				self.log("Responding for BREAKPOINT CLEAR")
				self.sendData(id, NODATA)
			
			elif(cmdsig == CREATESTRING_SIG):
				self.cstring = str(p['message'][4:])
				self.log("Extracted command '%s'" % (self.cstring))
				self.log("Responding for CREATESTRING")
				self.sendData(id, CREATESTRING_RES)
			
			elif(cmdsig == INVOKESTATICMETHOD_SIG):
				self.log("Responding for CLASS_INVOKE")
				self.sendData(id, INVOKESTATICMETHOD_RES)
			
			elif(cmdsig == INVOKEMETHOD_SIG):
				self.log("Responding for OBJECT_INVOKE")
				self.sendData(id, INVOKEMETHOD_RES)
				self.method = "jdwp-shellifier"
		
			elif(cmdsig == AUTOTEST_SIG):
				if str(p['message']) == AUTOTEST:
					self.log("Responding for AUTOTEST")
					self.transport.socket.send(AUTOTEST)
					self.transport.loseConnection()
			else:
				self.log("Nothing to send, input commands not recognized")
				self.transport.loseConnection()

def main():

	factory = Factory()
	factory.protocol = JDWPD
        reactor.listenTCP(hconfig.get('port', DEFAULT_PORT), factory)
        reactor.run()

if __name__ == "__main__":
    main()

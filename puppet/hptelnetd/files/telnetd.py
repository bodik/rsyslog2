#warden
from warden_client import Client, Error, read_cfg, format_timestamp
import json
import string
from time import time, gmtime, strftime, sleep
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
        client_proto, client_port, server_port, category, data):

        event = {
                "Format": "IDEA0",
                "ID": str(uuid4()),
                "DetectTime": detect_time,
                "Category": [category],
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

from twisted.conch.insults import insults
from twisted.conch.telnet import TelnetTransport, StatefulTelnetProtocol
from twisted.internet import protocol
import random

class telnetd(StatefulTelnetProtocol, object):
    DEF_USER = "root"
    DEF_PASS = "toor"
    MAX_LOGIN_COUNT = 3
    LOGIN_DELAY = 1
    PROMPT = "/ # "
    

    MSG_PRELOGIN = "User Access Verification\n\n"
    MSG_BADPASS = "Password incorrect.\n\n\n\n"
 
    state = 'User'
    logcount = 0
    _lastaction = None
    d = None
    
    ECHO  = chr(1)  # Server-to User:  States that the server is sending echos of the transmitted data.
                    # Sent only as a reply to ECHO or NO ECHO..

    CMD_DIR = "commands"
    CMD_REF = {
		"id"       : { "src" : "code", "ref" : "uid=0(root) gid=0(root) groups=0(root)"},
		"whoami"   : { "src" : "code", "ref" : "root"},
		"uname"    : { "src" : "code", "ref" : "Linux fc01 3.13.3-7-brocade #1 SMP x86_64 x86_64 Fabric OS"},
		"ifconfig" : { "src" : "file", "ref" : "ifconfig.cmd"},
		"ls"       : { "src" : "file", "ref" : "ls.cmd"},
	      }


    def telnet_Password(self, line):
	self._lastaction = "PASSWORD"
	self.transport.wont(self.ECHO)
	username, password = self.username, line
	login = self.checkCreds(username, password)
	self.transport.write("\n")
	if not login:
		self.transport.write(self.MSG_BADPASS)
		self.logcount += 1
		if self.logcount == self.MAX_LOGIN_COUNT:
			self.transport.loseConnection()
		else:
			sleep(self.LOGIN_DELAY)
			self.promptUsername()
        		self.state = "User"
        		return 'Discard'	
	else:
		self.transport.write(self.PROMPT)	
		self.state = 'Command'
		return 'Command' 


    def telnet_Command(self, cmd):
	self._lastaction = "COMMAND"
	if cmd != "":
	        wclient.logger.debug("command %s, %s" % (self._peer, cmd))
		self._data.append("%s" % (cmd))
		cmdbase = cmd.split(" ")[0].strip()
		if cmd == "exit" or cmd == "quit" or cmd == "q":
		    self.transport.loseConnection()
		    return 'Done'
		elif cmdbase not in self.CMD_REF:
		    self.transport.write("ash: %s command not found\n" % (cmdbase))
		else:
		    if self.CMD_REF[cmdbase]['src'] == "code":
			self.transport.write(self.CMD_REF[cmdbase]['ref'] + "\n")
		    elif self.CMD_REF[cmdbase]['src'] == "file":
			try:
				with open ("%s/%s" % (self.CMD_DIR, self.CMD_REF[cmdbase]['ref']), "r") as f:
					data = f.read()
					self.transport.write(data)
					f.close()
			except:
				self.transport.write("ash: %s command not found\n" % (cmdbase))
	
	self.transport.write(self.PROMPT)
        return 'Command'		

    def telnet_User(self, line):
        self._lastaction = "USERNAME"
	self.username = line
	self.transport.will(self.ECHO)
	self.transport.write("Password: ")
        return 'Password'
  
    def checkCreds(self, username, password):
	wclient.logger.debug("login %s, %s:%s" % (self._peer, username, password))
	self._data.append("%s:%s" % (username, password))
	if username == self.DEF_USER and password  == self.DEF_PASS:
		return True
	else:
		return False
 
    def connectionMade(self):
	try:
		# Cisco IOS fingerprint	
		self.transport.transport.socket.send('\xff\xfb\x01\xff\xfb\x03\xff\xfd\x18\xff\xfd\x1f')
	except:
		pass	

        self._lastaction = "CONNECTED"
        self._peer = self.transport.getPeer()
        self._socket = self.transport.transport.socket.getsockname()
        self._dtime = format_timestamp()
        self._data = []
        wclient.logger.debug("connected %s" % (self._peer))
	
	self.showBanner()
	self.promptUsername()
	
	self.state = 'User'
	return 'User'    

    def connectionLost(self, reason):
	lastaction = self._lastaction
	category = "Other"
	if lastaction == "CONNECTED":
		category = "Recon.Scanning"
	elif lastaction == "PASSWORD":
		category = "Attempt.Login"
	elif lastaction == "COMMAND":
		category = "Information.UnauthorizedAccess"
	elif lastaction == "USERNAME":
		pass # username entered
	elif lastaction == None:
		pass # this should not happen

        wclient.logger.debug("disconnected %s" % (self._peer))
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
		category = category,
		data = '--SEP--'.join(self._data)
        )
        #print "DEBUG: %s" % json.dumps(a, indent=2)
        ret = wclient.sendEvents([a])
        if 'saved' in ret:
        	wclient.logger.info("%d event(s) successfully delivered." % (ret['saved']))

    def showBanner(self):
 	self.transport.write("""
   !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
           Pozor! Cizi komunikacni zarizeni!
       Neautorizovany pristup zakazan dle zakona!
       Caution! Private communications equipment!
         Unauthorized access prohibited by law!
   !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!\n\n""")
	return

    def promptUsername(self):
	self.transport.write(self.MSG_PRELOGIN)
	self.transport.write("Username: ")

    def enableRemote(self, option):
	return False

    def disableRemote(self, option):
        pass

    def enableLocal(self, option):
	return False

    def disableLocal(self, option):
        pass

from twisted.internet import reactor, task
from twisted.internet.protocol import ServerFactory

factory = ServerFactory()
factory.protocol = lambda: TelnetTransport(telnetd)
reactor.listenTCP(23, factory)
reactor.run()

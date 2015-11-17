#!/usr/bin/python       
# -*- coding: utf-8 -*-
#                       

from warden_client import read_cfg, format_timestamp
from twisted.conch.telnet import TelnetTransport, StatefulTelnetProtocol
from twisted.internet.protocol import ServerFactory
from twisted.internet import reactor
from time import sleep
import json
import warden_utils_flab as w3u
import os

hconfig = read_cfg('telnetd.cfg')
logger = w3u.getLogger(hconfig['logfile'])

class telnetd(StatefulTelnetProtocol, object):
    DEF_USER = "root"
    DEF_PASS = "toor"
    DEF_AUTOTEST_USER = "autotest"
    DEF_AUTOTEST_PASS = "autotest.123456"
    MAX_LOGIN_COUNT = 3
    LOGIN_DELAY = 1
    PROMPT = "/ # "
    NEWLINE = "\n"
    
    MSG_PRELOGIN = "User Access Verification\n\n"
    MSG_BADPASS = "Password incorrect.\n\n\n\n"
 
    state = 'User'
    logcount = 0
    lastaction = None
    autotest = False
    
    ECHO  = chr(1)  # Server-to User:  States that the server is sending echos of the transmitted data.
                    # Sent only as a reply to ECHO or NO ECHO..

    CMD_DIR = "commands"
    
    def __init__(self):
	pass

    def telnet_Password(self, line):
	self.lastaction = "PASSWORD"
	self.transport.wont(self.ECHO)
	username, password = self.username, line
	login = self.checkCreds(username, password)
	self.transport.write(self.NEWLINE)
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
	self.lastaction = "COMMAND"
	if cmd != "":
		self._data.append("%s" % (cmd))
		args = cmd.split(" ")
		cmdbase = os.path.split(args[0].strip())[1]	
		
		cmdarg = ""
		if len(args) > 1:
			cmdarg = args[1].strip()		
	
		if cmd == "exit" or cmd == "quit" or cmd == "q":
		    self.transport.loseConnection()
		    return 'Done'
	
		f = None	
		try:
		        f = open ("%s/%s.json" % (self.CMD_DIR, cmdbase), "r")
			data = json.loads(f.read())
			if cmdarg in data.keys():	
				self.transport.write(str(data[cmdarg] + self.NEWLINE))
			else:	
				self.transport.write(str(data['default'] + self.NEWLINE))
		except:
			self.transport.write("ash: %s command not found%s" % (cmdbase, self.NEWLINE))
		finally:
			if f:
				f.close()
	
	self.transport.write(self.PROMPT)
        return 'Command'		

    def telnet_User(self, line):
        self.lastaction = "USERNAME"
	self.username = line
	self.transport.will(self.ECHO)
	self.transport.write("Password: ")
        return 'Password'
  
    def checkCreds(self, username, password):
	self._data.append("%s:%s" % (username, password))
	if username == self.DEF_AUTOTEST_USER and password == self.DEF_AUTOTEST_PASS:
		self.autotest = True
		return True

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

        self.lastaction = "CONNECTED"
        self._peer = self.transport.getPeer()
	self._srcip = self._peer.host
	self._srcport = self._peer.port
	self._proto = self._peer.type
        self._socket = self.transport.transport.socket.getsockname()
	self._dstip = self._socket[0]
	self._dstport = self._socket[1]
        self._dtime = format_timestamp()
        self._data = []
	
	self.showBanner()
	self.promptUsername()
	
	self.state = 'User'
	return 'User'    

    def connectionLost(self, reason):
	if self.autotest:
		return

	lastaction = self.lastaction
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

        data  = { 
		 "detect_time" : self._dtime,
		 "proto"       : self._peer.type.lower(),
		 "src_ip"      : self._peer.host,
		 "src_port"    : self._peer.port,
		 "dst_ip"      : self._socket[0],
		 "dst_port"    : self._socket[1],
		 "category"    : category,
		 "data"        : "\n".join(self._data),
        }
        
	logger.info(json.dumps(data))

    def showBanner(self):
 	self.transport.write("""
   !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
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

def main():
    factory = ServerFactory()
    factory.protocol = lambda: TelnetTransport(telnetd)
    reactor.listenTCP(hconfig['port'], factory)
    reactor.run()

if __name__ == "__main__":
    main()



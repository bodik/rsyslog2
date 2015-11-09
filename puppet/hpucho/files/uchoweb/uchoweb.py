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


DEFAULT_ACONFIG = 'warden_client-uchoweb.cfg'
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

def gen_event_idea_uchoweb(client_name, detect_time, conn_count, src_ip, dst_ip, anonymised, target_net, 
	peer_proto, peer_port, uchoweb_port, data):

	event = {
		"Format": "IDEA0",
		"ID": str(uuid4()),
		"DetectTime": detect_time,
		"Category": ["Other"],
		"Note": "Uchoweb event",
		"ConnCount": conn_count,
		"Source": [{ "Proto": peer_proto, "Port": [peer_port] }],
		"Target": [{ "Proto": peer_proto, "Port": [uchoweb_port] }],
		"Node": [
			{
				"Name": client_name,
				"Tags": ["Honeypot"],
				"SW": ["Uchoweb"],
			}
		],
		"Attach": [{ "request": data, "smart": data["requestline"] }]
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




#uchoweb2
import SimpleHTTPServer, SocketServer, logging, sys
import re, os, mimetypes, base64
from jinja2 import Environment, FileSystemLoader

content_base = os.path.join(os.getcwd(), "content/")
templates_base = os.path.join(os.getcwd(), "templates/")
port = aconfig.get('port', 8081)
personality = aconfig.get('personality', 'Apache Tomcat/7.0.56')


class ServerHandler(SimpleHTTPServer.SimpleHTTPRequestHandler):
	server_version = personality
	sys_version = ""

	def doAbort(self):
		j2_env = Environment(loader=FileSystemLoader(templates_base), trim_blocks=True)
		output = j2_env.get_template('404').render(path=self.path)
	        self.send_response(404)
	        self.end_headers()
        	self.wfile.write(output)


	def doRespond(self):

		#log
        	wclient.logger.info("=======")
	        wclient.logger.info(self.__dict__)
	        wclient.logger.info(str(self.headers))
		body_len = int(self.headers.getheader('content-length', 0))
		body_data = self.rfile.read(body_len)
	        wclient.logger.info(body_data)
        	wclient.logger.info("=======")
		
		#import pdb; pdb.set_trace()

		#report
		a = gen_event_idea_uchoweb(
			client_name = aname, 
			detect_time = format_timestamp(),
			conn_count = 1, 
			anonymised = aanonymised, 
			target_net = atargetnet,
	
			peer_proto = ["tcp", "http"],
	
			peer_port = self.client_address[1],
			src_ip = self.client_address[0],
	
			uchoweb_port = port,
			dst_ip = "0.0.0.0",
	
			data = { "requestline": self.requestline, "headers": str(self.headers), "body": base64.b64encode( body_data ), "body_len": body_len }
		)
		wclient.logger.debug("event %s" % json.dumps(a, indent=2))
		ret = wclient.sendEvents([a])
		if 'saved' in ret:
			wclient.logger.info("%d event(s) successfully delivered." % ret['saved'])


		#process request
		if self.path.endswith('/'):
			file_name = self.path+'index.html'
		else:
			file_name = self.path
		file_name = re.sub("^/", "", file_name)
		file_name = re.sub("/", "AAAA", file_name)
		file_name = re.sub("\?", "BBBB", file_name)
	
		try:	
			absolute_path = content_base+file_name
			normalized_path = os.path.normpath(absolute_path)
			if not normalized_path.startswith(content_base):
				return self.doAbort()
			f = open(normalized_path, "rb")
			mime_type = mimetypes.guess_type(normalized_path)[0]
			output = f.read()
			f.close()
		
		except Exception as e:
			wclient.logger.warning(e)
			return self.doAbort()

	        self.send_response(200)
	        self.send_header('Content-type', mime_type)
	        self.end_headers()
        	self.wfile.write(output)
		return

	def do_GET(self):
		self.doRespond()

	def do_POST(self):
		self.doRespond()


SocketServer.TCPServer.allow_reuse_address = True
httpd = SocketServer.TCPServer(("0.0.0.0", port), ServerHandler)
wclient.logger.info("starting server")
httpd.serve_forever()


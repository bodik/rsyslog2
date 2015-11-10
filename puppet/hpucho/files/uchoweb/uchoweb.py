#!/usr/bin/python

from warden_client import read_cfg, format_timestamp
from jinja2 import Environment, FileSystemLoader
import SimpleHTTPServer, SocketServer, logging, sys
import json
import os
import sys
import re
import base64
import w3utils_flab as w3u
import mimetypes

hconfig = read_cfg('uchoweb.cfg')

content_base = os.path.join(os.getcwd(), "content/")
templates_base = os.path.join(os.getcwd(), "templates/")
port = hconfig.get('port', 8081)
personality = hconfig.get('personality', 'Apache Tomcat/7.0.56')

logger = w3u.getLogger(hconfig['logfile'])

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

		body_len = int(self.headers.getheader('content-length', 0))
		body_data = self.rfile.read(body_len)
	
		data2log = {
			"detect_time" : format_timestamp(),
			"src_ip"      : self.client_address[0],
			"src_port"    : self.client_address[1],
			"dst_ip"      : self.request.getsockname()[0],
			"dst_port"    : port,
			"proto"       : ["tcp", "http"],
			"data"        : {"requestline": self.requestline, 
			  	         "headers"    : str(self.headers), 
				         "body"       : base64.b64encode(body_data), 
				         "body_len"   : body_len }
		}
		
		logger.info(json.dumps(data2log))
		
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
httpd = SocketServer.TCPServer(("", port), ServerHandler)
httpd.serve_forever()


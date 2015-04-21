#!/usr/bin/python
# -*- coding: UTF-8 -*-

import SimpleHTTPServer
import SocketServer
import sys, os
import subprocess
import socket
import urllib
import json

def resolve_client_address(ip=None):
	if hasattr(socket, 'setdefaulttimeout'):
		socket.setdefaulttimeout(5)

	try:
		hostname =  socket.gethostbyaddr(ip)
	except Exception as e:
		print "Unexpected error:", sys.exc_info()[0], e
                pass

	return hostname[0]




##def read_cfg(path):
##	with open(path, "r") as f:
##        	stripcomments = "\n".join((l for l in f if not l.lstrip().startswith(("#", "//"))))
##		conf = json.loads(stripcomments)
##	# Lowercase keys
##	conf = dict((sect.lower(), dict(
##		(subkey.lower(), val) for subkey, val in subsect.iteritems())
##		) for sect, subsect in conf.iteritems())
##	return conf




def getCertificate(self):
	hostname = resolve_client_address(self.client_address[0])
	data = subprocess.check_output(["/bin/sh", "warden_ca.sh", "get_crt", hostname])
	return data

def getCaCertificate(self):
	data = subprocess.check_output(["/bin/sh", "warden_ca.sh", "get_ca_crt"])
	return data

def getCrl(self):
	data = subprocess.check_output(["/bin/sh", "warden_ca.sh", "get_crl"])
	return data

def putCsr(self):
	hostname = resolve_client_address(self.client_address[0])
	filename = "ssl/ca/requests/%s.pem" % hostname
	try:
		length = int(self.headers['Content-Length'])
        	post_data = urllib.unquote(self.rfile.read(length).decode('utf-8'))

		try:
			data = subprocess.check_output(["/bin/sh", "warden_ca.sh", "revoke", hostname])
			data = subprocess.check_output(["/bin/sh", "warden_ca.sh", "clean", hostname])
		except Exception as e:
			pass

		the_file = open(filename, 'w')
		the_file.write(post_data)
		the_file.flush()
		the_file.close()

		if os.path.exists("AUTOSIGN"):
			print ("WARN: autosigning for %s" % hostname)
			try:
				data = subprocess.check_output(["/bin/sh", "warden_ca.sh", "sign", hostname])
			except Exception as e:
				print "Unexpected error:", sys.exc_info()[0], e, data
				raise

	except Exception as e:
		print "Unexpected error:", sys.exc_info()[0], e
		return 500
	
	return 200


	
def process_request(self):
	data = ""
	try:
		if self.path.startswith("/getCertificate"):
			data = getCertificate(self)
			self.send_response(200)
			self.end_headers()
			self.wfile.write(data)
		
		elif self.path.startswith("/getCaCertificate"):
			data = getCaCertificate(self)
			self.send_response(200)
			self.end_headers()
			self.wfile.write(data)

		elif self.path.startswith("/getCrl"):
			data = getCrl(self)
			self.send_response(200)
			self.end_headers()
			self.wfile.write(data)

		elif self.path.startswith("/putCsr"):
			data = putCsr(self)
			self.send_response(data)
			self.end_headers()

		else:
			self.send_response(404)
			self.end_headers()

	except Exception as e:
		print ("Unexpected error:", sys.exc_info()[0], e)
		self.send_error(500)






class MyHandler(SimpleHTTPServer.SimpleHTTPRequestHandler):
	def do_GET(self):
		process_request(self)

	def do_POST(self):
		process_request(self)

		
class MyTCPServer(SocketServer.TCPServer):
	def server_bind(self):
        	import socket
	        self.socket.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
        	self.socket.bind(self.server_address)

if __name__=="__main__":

	if sys.stdout.name == '<stdout>':
        	sys.stdout = os.fdopen(sys.stdout.fileno(), 'w', 0)
	if sys.stderr.name == '<stderr>':
        	sys.stderr = os.fdopen(sys.stderr.fileno(), 'w', 0)

	server_address = ('', 45444)
	httpd = MyTCPServer(server_address, MyHandler)
	try:
	    httpd.serve_forever()
	except KeyboardInterrupt:
	    pass
	httpd.server_close()


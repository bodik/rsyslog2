#!/usr/bin/python
# -*- coding: UTF-8 -*-

import SimpleHTTPServer
import SocketServer
import sys, os
import subprocess
import socket
import urllib
import json
from urlparse import urlparse, parse_qs

def _resolve_client_address(ip=None):
	if hasattr(socket, 'setdefaulttimeout'):
		socket.setdefaulttimeout(5)
	try:
		hostname =  socket.gethostbyaddr(ip)
	except Exception as e:
		print "Unexpected error:", sys.exc_info()[0], e
                pass
	return hostname[0]




def get_ca_crt(self):
	data = subprocess.check_output(["/bin/sh", "warden_ca.sh", "get_ca_crt"])
	return data

def get_ca_crl(self):
	data = subprocess.check_output(["/bin/sh", "warden_ca.sh", "get_ca_crl"])
	return data

def get_crt(self):
	hostname = _resolve_client_address(self.client_address[0])
	#TODO: validate in case attacker has very nasty PTR
	data = subprocess.check_output(["/bin/sh", "warden_ca.sh", "get_crt", hostname])
	return data




def _sign(dn):
	print ("WARN: autosigning for %s" % dn)
	try:
		data = subprocess.check_output(["/bin/sh", "warden_ca.sh", "sign", dn])
	except Exception as e:
		print "Unexpected error:", sys.exc_info()[0], e
		raise
	return 0



def put_csr(self):
	hostname = _resolve_client_address(self.client_address[0])
	filename = "ssl/ca/requests/%s.pem" % hostname
	try:
		length = int(self.headers['Content-Length'])
        	post_data = urllib.unquote(self.rfile.read(length).decode('utf-8'))

		#subseqent calls if we want to reissue certificate for same DN, cloud testing and such...
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
			_sign(hostname)

	except Exception as e:
		print "Unexpected error:", sys.exc_info()[0], e
		return 500
	
	return 200


def register_sensor(self):
	if os.path.exists("AUTOSIGN") == False:
		return 403

	try:
		qs = parse_qs(urlparse(self.path).query)
		if 'sensor_name' not in qs:
			print "ERROR: service s not present"
			return 400
	
		hostname = _resolve_client_address(self.client_address[0])
		hostname_rev = hostname.split(".")
		hostname_rev.reverse()
		hostname_rev = ".".join(hostname_rev)

		cmd = "/usr/bin/python /opt/warden_server/warden_server.py register -n %s -h %s -r bodik@cesnet.cz --read --write --notest" % (".".join([hostname_rev,qs['sensor_name'][0]]), hostname)
		print "DEBUG:",cmd
		data = subprocess.check_output(cmd.split(" "))

	except Exception as e:
		print "Unexpected error:", sys.exc_info()[0], e
		return 500

	return 200

	
def process_request(self):
	data = ""
	try:
		if self.path.startswith("/get_crt"):
			data = get_crt(self)
			self.send_response(200)
			self.end_headers()
			self.wfile.write(data)
		
		elif self.path.startswith("/get_ca_crt"):
			data = get_ca_crt(self)
			self.send_response(200)
			self.end_headers()
			self.wfile.write(data)

		elif self.path.startswith("/get_ca_crl"):
			data = get_ca_crl(self)
			self.send_response(200)
			self.end_headers()
			self.wfile.write(data)

		elif self.path.startswith("/put_csr"):
			data = put_csr(self)
			self.send_response(data)
			self.end_headers()

		elif self.path.startswith("/register_sensor"):
			data = register_sensor(self)
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


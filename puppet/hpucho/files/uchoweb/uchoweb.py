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
		"Category": ["Intrusion"],
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
		"Attach": [{ "request": data, "smart": data["url"] }]
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



#uchoweb
from flask import Flask, make_response, request, render_template
import json, os, re, mimetypes, base64

app = Flask(__name__, static_url_path='/non_existent_static_uri')
app.config.update(
	DEBUG=True
)
content_base = os.path.join(os.getcwd(), "content/")
port = aconfig.get('port', 8081)
personality = aconfig.get('personality', 'Apache Tomcat/7.0.56 (Debian)')
outputdir = aconfig.get('outputdir', '/var/spool/uchoweb')


def doAbort():
	return (render_template("404", path=request.path), 404)

def doRespond():
	if request.path.endswith('/'):
		file_name = request.path+'index.html'
	else:
		file_name = request.path
	file_name = re.sub("^/", "", file_name)
	file_name = re.sub("/", "AAAA", file_name)
	file_name = re.sub("\?", "BBBB", file_name)

	try:	
		absolute_path = content_base+file_name
		normalized_path = os.path.normpath(absolute_path)
		if not normalized_path.startswith(content_base):
			return doAbort()
		f = open(normalized_path, "rb")
		mime_type = mimetypes.guess_type(normalized_path)[0]
		output = f.read()
	
		resp = make_response(output)
		resp.headers["Content-Type"] = mime_type
	except:
		return doAbort()

	return resp

@app.route('/', defaults={'path': ''}, methods=["GET", "POST"])
@app.route('/<path:path>', methods=["GET", "POST"])
def catch_all(path):

	fls = []
	for f in request.files:
	#TODO: ITERATE ;(
		fls.append({
			"name": request.files[f].name,
			"filename": request.files[f].filename,
			"headers": str(request.files[f].headers),
			"content_type": request.files[f].content_type,
			"content_length": request.files[f].content_length,
			"content": base64.b64encode(  request.files[f].stream.read() )
		})
		
	#to get data throught flask ;(	
	a = gen_event_idea_uchoweb(
		client_name = aname, 
		detect_time = format_timestamp(),
		conn_count = 1, 
		anonymised = aanonymised, 
		target_net = atargetnet,

		peer_proto = ["tcp", "http"],

		peer_port = request.__dict__["environ"]["REMOTE_PORT"],
		src_ip = request.remote_addr,

		uchoweb_port = port,
		dst_ip = "0.0.0.0",

		data = { "url": request.url, "headers": str(request.headers), "files": fls }
	)
	wclient.logger.debug("event %s" % json.dumps(a, indent=2))
	ret = wclient.sendEvents([a])
	if 'saved' in ret:
		wclient.logger.info("%d event(s) successfully delivered." % ret['saved'])

	return doRespond()


#todo: postprocessing here
@app.after_request
def after_request(response):
	response.headers['server'] = personality
	return response




if __name__ == '__main__':
	app.run(host='0.0.0.0', port=port)


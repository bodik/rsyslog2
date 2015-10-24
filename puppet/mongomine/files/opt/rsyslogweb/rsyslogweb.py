import bottle
import pymongo
import bson
import bson.json_util
import json
import re
import socket
import subprocess
import time
import dateutil.parser
import dateutil.tz
import base64

import rsyslogweblib

import pprint
pp = pprint.PrettyPrinter(indent=4)

conn = pymongo.mongo_client.MongoClient("mongodb://localhost", w=1, tz_aware=True)
our_zone = dateutil.tz.gettz('CET')
utc_zone = dateutil.tz.gettz('UTC')


def list_columns(data=[]):
	columns = dict()
	for tmp in data:
		for i in tmp.keys():
			if type(tmp[i]) is dict:
				for j in tmp[i].keys():
					columns[i+"."+j] = 1
			else:
				columns[i] = 1
	cols = columns.keys()

	cols.sort()
	cols = [{"mDataProp":i, "sTitle":i, "sDefaultContent": ""} for i in cols ]
	return cols



@bottle.route('/')
@bottle.route('/stats')
def stats():
	return bottle.template('stats')






@bottle.route('/table_grokparsefailure')
def table_grokparsefailure():
	return bottle.template('table_grokparsefailure')

@bottle.route('/table_grokparsefailure_data')
def table_grokparsefailure_data():
	c = conn.sshd.log.find( { "@tags": "_grokparsefailure"} ).limit(300)
	data=[]
	for tmp in c:
		data.append(tmp)
	return bson.json_util.dumps({"aaData":data})





@bottle.route('/table_mapRemoteResult')
def table_mapRemoteResult():
	return bottle.template('table_mapRemoteResult')

@bottle.route('/table_mapRemoteResult_data')
def table_mapRemoteResult_data():
	c = conn.sshd.mapRemoteResult.find().sort("value.count", direction=-1).limit(50)
	data=[]
	for tmp in c:
		tmp["_id"]["remote"] = "<a href='search?collection=mapRemoteResultPerDay&remote=%s&submit=1'>%s</a>" % (tmp["_id"]["remote"], tmp["_id"]["remote"])
		data.append(tmp)
	return bson.json_util.dumps({"aaData":data})





@bottle.route('/table_mapCrackers')
def table_mapCrackers():
	return bottle.template('table_mapCrackers')

@bottle.route('/table_mapCrackers_data')
def table_mapCrackers_data():
	#todo: proc je tady >30 ??
	c = conn.sshd.mapCrackers.find({"value.count": {"$gt": 30}}).sort("value.count", direction=-1)
	data=[]
	for tmp in c:
		tmp["_id"]["remote"] = "<a href='search?collection=mapRemoteResultPerDay&remote=%s&submit=1'>%s</a>" % (tmp["_id"]["remote"], tmp["_id"]["remote"])
		data.append(tmp)
	return bson.json_util.dumps({"aaData":data})





@bottle.route('/table_mapResult')
def table_mapResult():
	return bottle.template('table_mapResult')

@bottle.route('/table_mapResult_data')
def table_mapResult_data():
	c = conn.sshd.mapResult.find().sort("value.count", direction=-1)
	data=[]
	for tmp in c:
		data.append(tmp)
	return bson.json_util.dumps({"aaData":data})





@bottle.route('/table_timingReduces')
def table_timingReduces():
	r = conn.sshd.command({ "collStats": "log" } )
	return bottle.template('table_timingReduces', total_docs=r['count'])

@bottle.route('/table_timingReduces_data')
def table_timingReduces_data():
	c = conn.sshd.timingReduces.find({"name": {"$regex": "^map"}}).sort("took", direction=-1)
	data=[]
	for tmp in c:
		link = "../rock/index.php?db=sshd&collection=timingReduces&action=collection.index&format=json&criteria={%0D%0A+%22name%22%3A+%22"+tmp['name']+"%22%0D%0A}&command=findAll"
		tmp['name'] = "<a href='%s'>%s</a>" % (link, tmp['name'])
		if (time.time()-tmp['created']) > (3600/2):
			tmp['age'] = "OLD"
		else:
			tmp['age'] = "OK"
		tmp["finished"]=time.ctime(tmp["finished"])
		data.append(tmp)
	return bson.json_util.dumps({"aaData":data})






@bottle.route('/graph_mapResultPerX')
def graph_mapResultPerX():
	per = bottle.request.query.per or "Day"
	return bottle.template('graph_mapResultPerX', per=per)

@bottle.route('/graph_mapResultPerX_data')
def graph_mapResultPerX_data():
	per = bottle.request.query.per or "Day"

	## authorized je jenom autorizacni oznameni a je "dublovano" accepted
	## invalid je dublovano failem
	query = {"_id.result": { "$not": { "$in": ["Authorized", "Invalid"]}}}
	
	#TODO: injection
	c = conn.sshd["mapResultPer"+per].find(query).sort("_id.t", direction=1).limit(1500)

	data=dict()
	for tmp in c:
		result = tmp["_id"]["result"]
		if not result in data:
			data[result] = []
		data[result].append( [ int(tmp['_id']['t'].astimezone(our_zone).strftime("%s"))*1000, (tmp["value"]["count"]) ] )

	return json.dumps( [ {"name":i, "data":data[i] } for i in sorted(data) ] )






@bottle.route('/graph_mapLogPerX')
def graph_mapLogPerX():
	per = bottle.request.query.per or "Day"
	return bottle.template('graph_mapLogPerX', per=per)

@bottle.route('/graph_mapLogPerX_data')
def graph_mapLogPerX_data():
	per = bottle.request.query.per or "Day"
	#TODO: fix mongodb injection
	c = conn.sshd["mapLogPer"+per].find().sort("_id.t", direction=1)
	data = []
	for tmp in c:
		data.append([
			int(tmp['_id']['t'].astimezone(our_zone).strftime("%s"))*1000, 
			tmp['value']['count']
		])
	return json.dumps([{ "name":"count", "data":data} ])






@bottle.route('/dropmaps')
def dropmaps():
	#TODO: refactor listcollections


	# lock cron mutex
	lock_path = "/tmp/rsyslogweb-maps.lock"
	if os.path.exists(lock_path):
		return "lockfile exists. not running"
	else:
		file = open(lock_path, 'w')
		file.write('')
		file.close()


	conn.sshd.internalData.remove({"type": "reduce", "name":"log"})
	clist = conn.sshd.collection_names()
	for i in clist:
		if re.match("^map", i):
			conn.sshd[i].remove({})
			conn.sshd.timingReduces.remove({"name":i})

	# unlock cron mutex
	os.unlink(lock_path)

	bottle.redirect('stats')



@bottle.route('/makemaps')
def make():
	out = subprocess.check_output("python /opt/rsyslogweb/maps3.py", shell=True)
	return bottle.template('pre',pre=out)




@bottle.route('/search_data')
def search_data():
	if not bottle.request.query.query or not bottle.request.query.limit or not bottle.request.query.collection:
		return

	query = bson.json_util.loads(base64.b64decode(bottle.request.query.get('query')))
	limit = int(bottle.request.query.get("limit"))
	collection = bottle.request.query.get("collection")

        if collection == "log":
		sort_field = "t"
	else:
		sort_field = "_id.t"

	data = []
	c = conn.sshd[collection].find(query).sort(sort_field, direction=-1).limit(limit)
        if collection == "log":
		for tmp in c:
			if "t" in tmp:
				tmp['@0t'] = tmp["t"].astimezone(our_zone).ctime()
				del tmp["t"]

			if "remote" in tmp:
					#TODO: tohle je spatne
					a = "".join(tmp["remote"])
					tmp["remote"] = "<a href='profile_remote?remote="+a+"'>"+a+"</a>"
		
			if "@timestamp" in tmp:
				del tmp["@timestamp"]
			if "@version" in tmp:
				del tmp["@version"]
			if "pid" in tmp:
				del tmp["pid"]
			if "message" in tmp:
				del tmp["message"]
			if "tags" in tmp:
				del tmp["tags"]
			if ("geoip" in tmp) and ("location" in tmp["geoip"]):
				del tmp["geoip"]["location"]

			data.append(tmp)
        else:
               	for tmp in c:
			if "t" in tmp["_id"]:
				#dost blbej zpusob jak dostat cas dopredu :)
				tmp["_id"]["0t"] = tmp["_id"]["t"].astimezone(our_zone).ctime()
				del tmp["_id"]["t"]

			if "remote" in tmp["_id"]:
				a = "".join(tmp["_id"]["remote"])
				tmp["_id"]["remote"] = "<a href='profile_remote?remote="+a+"'>"+a+"</a>"

			data.append(tmp)

	columns = []
	if len(data):
		columns = list_columns(data)
	
	return bson.json_util.dumps({"aaData":data, "aoColumns":columns  }, sort_keys=True, indent=1, separators=(',', ': '))


@bottle.route('/search', method=['GET', 'POST'])
def search():
	#TODO: tohle se asi nemusi delat pres distinct, je to tady jako pozustatek reuse z kodu grafu (kde to v zasade asi taky nemusi uz byt kdyz mam finalizovanou mapu)
	# priprava dat pro formular ve view
	r = conn.sshd.command({ "distinct": "mapResult", "key": "_id.result"} )
	r1 = conn.sshd.command({ "distinct": "mapMethod", "key": "_id.method"} )
	collections = conn.sshd.collection_names()
	collections.sort()
	data=[]
	query = {"@tags": {"$not":{"$in": ["_grokparsefailure"]}} }
	found=0


	# porebirani dat z GET rekvestu
	#totok asi bude chtit nejak rozsirit
	if bottle.request.query.collection:
		bottle.request.forms['collection']=bottle.request.query.get('collection')
	if bottle.request.query.remote:
		bottle.request.forms['remote']=bottle.request.query.get('remote')
	if bottle.request.query.user:
		bottle.request.forms['user']=bottle.request.query.get('user')

	
	# nastaveni defaultniho namespacu pro vyhledavani, LS to bude stejne menit a po MR je to v _id
        if bottle.request.forms.collection == "log":
		base = ""
		ts_field = "t"
	else:
		base = "_id."
		ts_field = "_id.t"


	if bottle.request.forms.timestamp_begin:
		if not re.match(".*[+-]\d\d:\d\d$", bottle.request.forms.get('timestamp_begin')):
			bottle.request.forms['timestamp_begin'] = bottle.request.forms['timestamp_begin'] + " CET"

		bottle.request.forms['timestamp_begin'] = dateutil.parser.parse(bottle.request.forms.get('timestamp_begin'))
		if not ts_field in query:
			query[ts_field]=dict()
		query[ts_field]["$gte"] = bottle.request.forms.get('timestamp_begin').astimezone(utc_zone)
	if bottle.request.forms.timestamp_end:
		if not re.match(".*[+-]\d\d:\d\d$", bottle.request.forms.get('timestamp_end')):
			bottle.request.forms['timestamp_end'] = bottle.request.forms['timestamp_end'] + " CET"

		bottle.request.forms['timestamp_end'] = dateutil.parser.parse(bottle.request.forms.get('timestamp_end'))
		if not ts_field in query:
			query[ts_field]=dict()
		query[ts_field]["$lte"] = bottle.request.forms.get('timestamp_end').astimezone(utc_zone)


	if bottle.request.forms.logsource:
		query[base+'logsource'] = bottle.request.forms.get('logsource')
	if bottle.request.forms.user:
		query[base+'user'] = bottle.request.forms.get('user')
	if bottle.request.forms.principal:
		query[base+'principal'] = bottle.request.forms.get('principal')
	if bottle.request.forms.remote:
		query[base+'remote'] = bottle.request.forms.get('remote')



	if bottle.request.forms.methods:
		query[base+'method'] = {"$in":bottle.request.forms.getall('methods')}
	if bottle.request.forms.results:
		query[base+'result'] = {"$in":bottle.request.forms.getall('results')}


	if not bottle.request.forms.limit:
		bottle.request.forms['limit'] = 100
	if not bottle.request.forms.collection:
		bottle.request.forms['collection'] = "mapLogsourceUserMethodRemoteResultPerDay"



	if bottle.request.query.query:
		query = bson.json_util.loads(base64.b64decode(bottle.request.query.get('query')))
		limit = int(bottle.request.query.get("limit"))
		collection = bottle.request.query.get("collection")


	if bottle.request.forms.submit or bottle.request.query.submit:
	        #found = conn.sshd[bottle.request.forms.collection].find(query).count()
		# spocitat to trva zbytecne dlouho, musim tam dat index nebo neco jineho na urychleni
	        found = "TODO"
	
	return bottle.template('search', 
		forms=bottle.request.forms,
		collections=collections,
		results=r["values"],
		methods=r1["values"],
		found=found, 
		query=query
		)


	



@bottle.route('/graph_mapRemoteResultPerX')
def graph_mapRemoteResultPerX():
	per = bottle.request.query.per or "Day"
	#TODO: remote regex ??
	remote = bottle.request.query.get('remote') or ""
	return bottle.template('graph_mapRemoteResultPerX', per=per, remote=remote)

@bottle.route('/graph_mapRemoteResultPerX_data')
def graph_mapRemoteResultPerX_data():
	per = bottle.request.query.per or "Day"
	#TODO: remote regex ??
	remote = bottle.request.query.remote or ""

	## authorized je jenom autorizacni oznameni a je "dublovano" accepted
	## invalid je dublovano failem
	query = {"_id.remote": remote }
	
	#TODO: injection
	c = conn.sshd["mapRemoteResultPer"+per].find(query).sort("_id.t", direction=1).limit(1500)

	data=dict()
	for tmp in c:
		result = tmp["_id"]["result"]
		if not result in data:
			data[result] = []
		data[result].append( [ int(tmp['_id']['t'].astimezone(our_zone).strftime("%s"))*1000, tmp["value"]["count"] ] )

	return json.dumps( [ {"name":i, "data":data[i] } for i in sorted(data) ] )




import GeoIP
def geoip(ip):
	gi = GeoIP.new(GeoIP.GEOIP_STANDARD)
	#TODO: fuj
	gi = GeoIP.open("/opt/logstash/vendor/geoip/GeoLiteCity.dat", gi.GEOIP_STANDARD)
    	geoRecord = gi.record_by_addr(ip)
	return geoRecord


@bottle.route('/profile_remote')
def profile_remote():
	if bottle.request.query.hostname:
		bottle.request.forms['hostname'] = bottle.request.query.get('hostname',"")
	if bottle.request.query.remote:
		bottle.request.forms['remote'] = bottle.request.query.get('remote', "")

	if bottle.request.forms.hostname and not bottle.request.forms.remote:
		try:
			bottle.request.forms['remote'] = socket.gethostbyname(bottle.request.forms.get('hostname'))
		except socket.herror:
			print "doing nothing"
        
	if not bottle.request.forms.hostname and bottle.request.forms.remote:
		try:
			bottle.request.forms['hostname'] = socket.gethostbyaddr(bottle.request.forms.get('remote'))
		except socket.herror:
			print "doing nothing"
	cp=dict()
        cp['remoteresult'] = [i for i in conn.sshd.mapRemoteResult.find({"_id.remote" : bottle.request.forms.get('remote')})]
	cp['geo'] =geoip(bottle.request.forms.get('remote', ""))

	listed = rsyslogweblib.remote_listed(bottle.request.forms.get('remote'), conn)
	return bottle.template('profile_remote', forms=bottle.request.forms, profile=cp, listed=listed)







@bottle.route('/cracks_list')
def list_cracks():
	return bottle.template('cracks_list')

@bottle.route('/cracks_list_data')
def list_cracks_data():
	crackers = rsyslogweblib.get_evil_list(conn)

	smap = "mapLogsourceUserMethodRemoteResultPerDay"
	base = "_id"
	query = {
		base+".remote": { "$in": crackers},
	        base+".result": { "$in" : ['Accepted', 'Authorized']}
	}

	c = conn.sshd[smap].aggregate([
		{ "$match": query },
	        { "$group": {"_id": { "remote": "$_id.remote", "user": "$_id.user", "result": "$_id.result", "logsource": "$_id.logsource" }, "count": {"$sum": "$value.count"}}},
	        { "$sort": bson.son.SON([("_id.remote", 1), ("count", -1)])}
	])

	data=[]	
	if c:
		for tmp in c:
			if "remote" in tmp["_id"]:
				a = "".join(tmp["_id"]["remote"])
				tmp["_id"]["remote"] = "<a href='profile_remote?remote="+a+"'>"+a+"</a>"
			data.append(tmp)

	columns = []
	if len(data):
		columns = list_columns(data)

	return bson.json_util.dumps({"aaData":data, "aoColumns":columns  }, sort_keys=True, indent=1, separators=(',', ': '))



@bottle.route('/alerts')
def alerts():
	return bottle.template('alerts')
@bottle.route('/alerts_data')
def alerts():
	c = conn.sshd.internalData.find({"type":"alert"}, {"_id":0})
	data=[]
	for tmp in c:
		tmp['0reported_on'] = tmp["reported_on"].astimezone(our_zone).ctime()
		del(tmp["reported_on"])
		tmp["remote"] = "<a href='profile_remote?remote="+tmp["remote"]+"'>"+tmp["remote"]+"</a>"
		data.append(tmp)

	columns = []
	if len(data):
		columns = list_columns(data)
	
	return bson.json_util.dumps({"aaData":data, "aoColumns":columns  }, sort_keys=True, indent=1, separators=(',', ': '))
	




@bottle.route('/cracks_whitelist')
def cracks_whitelist():
	remote = bottle.request.query.get('remote',"")
	c = conn.sshd.cracksWhitelist.find({}, {"_id":0})
	return bottle.template('cracks_whitelist', data=[i for i in c ], remote=remote)

@bottle.route('/cracks_whitelist_add')
def cracks_whitelist_add(remote=None):
	remote = bottle.request.query.get('remote')
	note = bottle.request.query.get('note')
	conn.sshd.cracksWhitelist.insert({"remote": remote, "note": note, "owner": bottle.request.environ.get('REMOTE_USER', "")})
	bottle.redirect('cracks_whitelist')
	
@bottle.route('/cracks_whitelist_del')
def cracks_whitelist_del(remote=None):
	remote = bottle.request.query.get('remote')
	d = conn.sshd.cracksWhitelist.remove({"remote": remote})
	bottle.redirect('cracks_whitelist')








@bottle.route('/cracks_blacklist')
def cracks_blacklist():
	remote = bottle.request.query.get('remote',"")
	c = conn.sshd.cracksBlacklist.find({}, {"_id":0})
	return bottle.template('cracks_blacklist', data=[i for i in c ], remote=remote)

@bottle.route('/cracks_blacklist_add')
def cracks_blacklist_add(remote=None):
	remote = bottle.request.query.get('remote')
	note = bottle.request.query.get('note')
	conn.sshd.cracksBlacklist.insert({"remote": remote, "note": note, "owner": bottle.request.environ.get('REMOTE_USER', "")})
	bottle.redirect('cracks_blacklist')
	
@bottle.route('/cracks_blacklist_del')
def cracks_blacklist_del(remote=None):
	remote = bottle.request.query.get('remote')
	d = conn.sshd.cracksBlacklist.remove({"remote": remote})
	bottle.redirect('cracks_blacklist')





@bottle.route('/warden_list')
def warden_list():
	wardenlist = rsyslogweblib.get_wardenlist(conn)
	return bottle.template('warden_list', wardenlist=wardenlist)



@bottle.route('/tor_list')
def tor_list():
	torlist = rsyslogweblib.get_torlist(conn)
	return bottle.template('warden_list', wardenlist=torlist)


@bottle.route('/')
def index():
	return bottle.template('index')
@bottle.route('/webmenu')
def webmenu():
	return bottle.template('webmenu')
@bottle.route('/datatables/<filename:path>')
def send_static(filename):
    return bottle.static_file(filename, root='datatables')
@bottle.route('/static/<filename:path>')
def send_static(filename):
    return bottle.static_file(filename, root='static')



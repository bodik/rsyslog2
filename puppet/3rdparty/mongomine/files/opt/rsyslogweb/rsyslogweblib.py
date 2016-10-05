import bson.son

def get_whitelist(conn):
	return  [i['remote'] for i in conn.sshd.cracksWhitelist.find({}, {"remote":1, "_id":0})]

def get_blacklist(conn):
	return  [i['remote'] for i in conn.sshd.cracksBlacklist.find({}, {"remote":1, "_id":0})]

def get_wardenlist(conn):
	ret = []
	r = conn.warden.events.aggregate([
		{ "$project": {"source":1, "_id":0} },
        	{ "$group": {"_id": "$source" }}
	])
	if r:
		for i in r:
			ret.append(i["_id"])
	return ret

def get_torlist(conn):
	ret = []
	r = conn.tor.lists.aggregate([
		{ "$project": {"ip":1, "_id":0} },
        	{ "$group": {"_id": "$ip" }}
	])
	if r:
		for i in r:
			ret.append(i["_id"])
	return ret

def get_cracklist(conn):
	crackers = []
	#TODO: velikost vracenych dat vs distinct
	r = conn.sshd.command({ "distinct": "mapCrackers", "key": "_id.remote"} )
	if "values" in r:
		crackers = r["values"]
	return crackers



# crackers list is combination of mapCrackers, whitelist, blacklist, torlist
def get_evil_list(conn):
	evil = get_cracklist(conn)
	whitelist = get_whitelist(conn)
	for i in whitelist:
		if i in evil:
			evil.remove(i)
	
	return (evil + get_blacklist(conn) + get_wardenlist(conn) + get_torlist(conn))


def remote_listed(remote,conn):
	listed = []
	if remote in get_cracklist(conn):
		listed.append("mapCrackers")
	if remote in get_whitelist(conn):
		listed.append("whitelisted")
	if remote in get_blacklist(conn):
		listed.append("blacklisted")
	if remote in get_wardenlist(conn):
		listed.append("wardenlisted")
	if remote in get_torlist(conn):
		listed.append("torlisted")
	return listed
	




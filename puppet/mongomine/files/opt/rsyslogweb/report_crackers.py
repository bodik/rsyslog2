#!/usr/bin/python

import pymongo
import time
import datetime
import dateutil.parser
import dateutil.tz
import sys

import json

import rsyslogweblib

import pprint
pp = pprint.PrettyPrinter(indent=4, depth=2)
def printf(format, *args):
    sys.stdout.write(format % args)


def gen_alert(remote):
	alert = dict()
	alert['remote'] = remote
	alert['search_url'] = "/rsyslogweb/search?remote="+remote
	alert['profile_url'] = "/rsyslogweb/profile_remote?remote="+remote
	c = conn.sshd.mapRemoteResult.find({"_id.remote": remote})
	alert['profile'] = [{i["_id"]["result"]: i["value"]["count"]}  for i in c]

	alert['listed'] = rsyslogweblib.remote_listed(remote, conn)
	
	now = datetime.datetime.now(our_zone)
	conn.sshd.internalData.update({"type": "alert", "remote":remote},{"$set": {"reported_on": now}}, upsert=True)

	print json.dumps(alert, sort_keys=True, indent=1, separators=(',', ': '))



conn = pymongo.mongo_client.MongoClient("mongodb://localhost", w=1, tz_aware=True)
our_zone = dateutil.tz.gettz('CET')
utc_zone = dateutil.tz.gettz('UTC')


# ip list with susspicious accesses
crackers = rsyslogweblib.get_evil_list(conn)

# find successfull accesses from those remotes
smap = "mapLogsourceUserMethodRemoteResultPerDay"
base = "_id"
query = {
	base+".remote": { "$in": crackers},
        base+".result": { "$in" : ['Accepted', 'Authorized']}
}
# aggregated, for every ip is then generated simple profile anyway
c = conn.sshd[smap].aggregate([
	{ "$match": query },
        { "$group": {"_id": "$_id.remote" }}
])


now = datetime.datetime.now(our_zone)
# class datetime.timedelta([days[, seconds[, microseconds[, milliseconds[, minutes[, hours[, weeks]]]]]]])
alert_horizont = datetime.timedelta(14)

for tmp in c:
	remote = tmp["_id"]

	c = conn.sshd.internalData.find_one({"type": "alert", "remote": remote})
	if (not c) or (c["reported_on"] < (now-alert_horizont)):
		print "Generating alert for %s" % remote
		gen_alert(remote)
	#else:
	#	print "Suppresing alert for %s" % remote
	

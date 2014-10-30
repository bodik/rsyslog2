#!/usr/bin/python2

import sys
import pymongo
from time import sleep

try:
    # new pymongo
    from bson.son import SON
except ImportError:
    # old pymongo
    from pymongo.son import SON

# BEGIN CONFIGURATION

# some settings can also be set on command line. start with --help to see options

CHUNK_SIZE=64 # in MB (make small to test splitting)
MONGOS_PORT=27017
N_SHARDS=4
USE_SSL=False # set to True if running with SSL enabled

# defaults -- can change on command line
COLLECTION_KEYS = {
	'sshd.log' : '@timestamp',
	'sshd.mapLogsourceUserMethodRemoteResultPerHour' : '_id',
        'sshd.mapLogsourceUserMethodRemoteResultPerDay' : '_id',
        'sshd.mapLogsourceUserMethodRemoteResultPerMonth' : '_id',

	'mentat.idmef': 'Alert.DetectTime', 

	'warden.events': '_id',
	'tor.lists': '_id'
}
#COLLECTION_KEYS = {'test.a' : 'a' }


# END CONFIGURATION

conn = pymongo.Connection('localhost', MONGOS_PORT)
admin = conn.admin

for i in range(1, N_SHARDS+1):
	sleep(1.0)
	try:
		print "INFO: adding shard "+'localhost:'+str(30000+i)
		admin.command('addshard', 'localhost:'+str(30000+i), allowLocal=True)
		#admin.command('addshard', 'localhost:3000'+str(i), allowLocal=True)
	except Exception as e:
		print "Unexpected error:", sys.exc_info()[0]
		print e
		pass


for database in ['test', 'sshd', 'mentat', 'warden', 'tor', 'autotest']:
	try:
		admin.command('enablesharding', database)
	except Exception as e:
		print "Unexpected error:", sys.exc_info()[0]
		print e
		pass


#TODO: fuj, takhle hnusne to mit udelany, ale celej tenhle skript je trosku moc slozitej
for (collection, keystr) in COLLECTION_KEYS.iteritems():
    (db,col)=collection.split('.')
    conn[db][col].ensure_index([(keystr,1)])
    admin.command('shardcollection', collection, key=SON((k,1) for k in keystr.split(',')))

# app indexes
for index in ["@timestamp", "@fields.logsource", "@fields.user", "@fields.method", "@fields.remote", "@fields.result", "@fields.principal", "@tags"]:
    conn.sshd.log.ensure_index([(index,1)])

for index in ["_id.t", "_id.logsource", "_id.user", "_id.method", "_id.remote", "_id.result", "_id.principal"]:
    for coll in ["mapLogsourceUserMethodRemoteResultPerHour", "mapLogsourceUserMethodRemoteResultPerDay", "mapLogsourceUserMethodRemoteResultPerMonth"]:
    	    conn.sshd[coll].ensure_index([(index,1)])

for index in ["ip"]:
    conn.tor.lists.ensure_index([(index,1)])

admin.command('shardcollection', 'test.fs.files', key={'_id':1})
admin.command('shardcollection', 'test.fs.chunks', key={'files_id':1})


# just to be safe
sleep(2)

print 'INFO: mongomine ready'


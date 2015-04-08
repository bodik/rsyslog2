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


if len(sys.argv)>1 and sys.argv[1]:
	N_SHARDS=int(sys.argv[1])
else:
	N_SHARDS=4

CHUNK_SIZE=64 # in MB (make small to test splitting)
MONGOS_PORT=27017
SHARDS_PORT_BASE=30000
USE_SSL=False # set to True if running with SSL enabled

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

conn = pymongo.MongoClient('localhost', MONGOS_PORT)
admin = conn.admin

for i in range(1, N_SHARDS+1):
	sleep(1.0)
	try:
		print "INFO: adding shard "+'localhost:'+str(SHARDS_PORT_BASE+i)
		admin.command('addshard', 'localhost:'+str(SHARDS_PORT_BASE+i), allowLocal=True)
	except Exception as e:
		print "WARN: Unexpected error:", sys.exc_info()[0]
		print e
		print "WARN: trying to continue to setup mongomine"
		pass




for database in ['test', 'sshd', 'mentat', 'warden', 'tor', 'autotest']:
	try:
		admin.command('enablesharding', database)
	except Exception as e:
		print "Unexpected error:", sys.exc_info()[0]
		print e
		print "WARN: trying to continue to setup mongomine"
		pass




#TODO: fuj, takhle hnusne to mit udelany, ale celej tenhle skript je trosku moc slozitej
for (collection, keystr) in COLLECTION_KEYS.iteritems():
	(db,col)=collection.split('.')
	conn[db][col].ensure_index([(keystr,1)])
	try:
		admin.command('shardcollection', collection, key=SON((k,1) for k in keystr.split(',')))
	except Exception as e:
		print "Unexpected error:", sys.exc_info()[0]
		print e
		print "WARN: trying to continue to setup mongomine"
		pass





# app indexes
for index in ["@timestamp", "@fields.logsource", "@fields.user", "@fields.method", "@fields.remote", "@fields.result", "@fields.principal", "@tags"]:
	try:
    		conn.sshd.log.ensure_index([(index,1)])
	except Exception as e:
		print "Unexpected error:", sys.exc_info()[0]
		print e
		print "WARN: trying to continue to setup mongomine"
		pass




for index in ["_id.t", "_id.logsource", "_id.user", "_id.method", "_id.remote", "_id.result", "_id.principal"]:
	for coll in ["mapLogsourceUserMethodRemoteResultPerHour", "mapLogsourceUserMethodRemoteResultPerDay", "mapLogsourceUserMethodRemoteResultPerMonth"]:
    		try:
	    		conn.sshd[coll].ensure_index([(index,1)])
		except Exception as e:
			print "Unexpected error:", sys.exc_info()[0]
			print e
			print "WARN: trying to continue to setup mongomine"
			pass




for index in ["ip"]:
    	try:
    		conn.tor.lists.ensure_index([(index,1)])
	except Exception as e:
		print "Unexpected error:", sys.exc_info()[0]
		print e
		print "WARN: trying to continue to setup mongomine"
		pass



try:
	admin.command('shardcollection', 'test.fs.files', key={'_id':1})
	admin.command('shardcollection', 'test.fs.chunks', key={'files_id':1})
except Exception as e:
	print "Unexpected error:", sys.exc_info()[0]
	print e
	print "WARN: trying to continue to setup mongomine"
	pass


# just to be safe
sleep(2)

print 'INFO: mongomine ready'


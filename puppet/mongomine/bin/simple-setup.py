#!/usr/bin/python2

import os
import sys
import shutil
import pymongo
import atexit

from socket import error, socket, AF_INET, SOCK_STREAM
from select import select
from subprocess import Popen, PIPE, STDOUT
from threading import Thread
from time import sleep

try:
    # new pymongo
    from bson.son import SON
except ImportError:
    # old pymongo
    from pymongo.son import SON

# BEGIN CONFIGURATION

# some settings can also be set on command line. start with --help to see options

BASE_DATA_PATH='data/db/sharding/' #warning: gets wiped every time you run this
MONGO_PATH=os.getenv( "MONGO_HOME" , os.path.expanduser('~/10gen/mongo/') )
N_SHARDS=16
N_CONFIG=1 # must be either 1 or 3
N_MONGOS=1
CHUNK_SIZE=64 # in MB (make small to test splitting)
MONGOS_PORT=27017 if N_MONGOS == 1 else 10000 # start at 10001 when multi
USE_SSL=False # set to True if running with SSL enabled

CONFIG_ARGS=[]
MONGOS_ARGS=[]
MONGOD_ARGS=[]

# Note this reports a lot of false positives.
USE_VALGRIND=False
VALGRIND_ARGS=["valgrind", "--log-file=/tmp/mongos-%p.valgrind", "--leak-check=yes", 
               ("--suppressions="+MONGO_PATH+"valgrind.suppressions"), "--"]

# see http://pueblo.sourceforge.net/doc/manual/ansi_color_codes.html
CONFIG_COLOR=31 #red
MONGOS_COLOR=32 #green
MONGOD_COLOR=36 #cyan
BOLD=True

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

def AFTER_SETUP():
    # feel free to change any of this
    # admin and conn are both defined globaly
    admin.command('enablesharding', 'test')
    admin.command('enablesharding', 'sshd')
    admin.command('enablesharding', 'mentat')
    admin.command('enablesharding', 'warden')
    admin.command('enablesharding', 'tor')

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


# END CONFIGURATION

for x in sys.argv[1:]:
    opt = x.split("=", 1)
    if opt[0] != '--help' and len(opt) != 2:
        raise Exception("bad arg: " + x )
    
    if opt[0].startswith('--'):
        opt[0] = opt[0][2:].lower()
        if opt[0] == 'help':
            print sys.argv[0], '[--help] [--chunksize=200] [--port=27017] [--path=/where/is/mongod] [collection=key]'
            sys.exit()
        elif opt[0] == 'chunksize':
            CHUNK_SIZE = int(opt[1])
        elif opt[0] == 'port':
            MONGOS_PORT = int(opt[1])
        elif opt[0] == 'path':
            MONGO_PATH = opt[1]
        elif opt[0] == 'usevalgrind': #intentionally not in --help
            USE_VALGRIND = int(opt[1])
        else:
            raise( Exception("unknown option: " + opt[0] ) )
    else:
        COLLECTION_KEYS[opt[0]] = opt[1]

if MONGO_PATH[-1] != '/':
    MONGO_PATH = MONGO_PATH+'/'

print( "MONGO_PATH: " + MONGO_PATH )

if not USE_VALGRIND:
    VALGRIND_ARGS = []

# fixed "colors"
RESET = 0
INVERSE = 7

#if os.path.exists(BASE_DATA_PATH):
#    print( "removing tree: %s" % BASE_DATA_PATH )
#    shutil.rmtree(BASE_DATA_PATH)

mongod = MONGO_PATH + 'mongod'
mongos = MONGO_PATH + 'mongos'

devnull = open('/dev/null', 'w+')

fds = {}
procs = []

def killAllSubs():
    for proc in procs:
        try:
            proc.terminate()
        except OSError:
            pass #already dead
atexit.register(killAllSubs)

def mkcolor(colorcode): 
    base = '\x1b[%sm'
    if BOLD:
        return (base*2) % (1, colorcode)
    else:
        return base % colorcode

def ascolor(color, text):
    return mkcolor(color) + text + mkcolor(RESET)

def waitfor(proc, port):
    trys = 0
    while proc.poll() is None and trys < 180: # nympha prealokuje journal hodne dlouho
        trys += 1
        s = socket(AF_INET, SOCK_STREAM)
        try:
            try:
                s.connect(('localhost', port))
                return
            except (IOError, error):
                sleep(1)
        finally:
            s.close()

    #extra prints to make line stand out
    print
    print proc.prefix, ascolor(INVERSE, 'failed to start')
    print
    
    sleep(1)
    killAllSubs()
    sys.exit(1)


def printer():
    while not fds: sleep(0.01) # wait until there is at least one fd to watch

    while fds:
        (files, _ , errors) = select(fds.keys(), [], fds.keys(), 1)
        for file in set(files + errors):
            # try to print related lines together
            while select([file], [], [], 0)[0]:
                line = file.readline().rstrip()
                if line:
                    print fds[file].prefix, line
                else:
                    if fds[file].poll() is not None:
                        print fds[file].prefix, ascolor(INVERSE, 'EXITED'), fds[file].returncode
                        del fds[file]
                        break
                break

printer_thread = Thread(target=printer)
printer_thread.start()


configs = []
for i in range(1, N_CONFIG+1):
    path = BASE_DATA_PATH +'config_' + str(i)
    try:
      os.makedirs(path)
    except:
      print "exists ", path
    config = Popen([mongod, '--port', str(20000 + i), '--configsvr', '--dbpath', path] + CONFIG_ARGS, stdin=devnull, stdout=PIPE, stderr=STDOUT)
    config.prefix = ascolor(CONFIG_COLOR, 'C' + str(i)) + ':'
    fds[config.stdout] = config
    procs.append(config)
    waitfor(config, 20000 + i)
    configs.append('localhost:' + str(20000 + i))


for i in range(1, N_SHARDS+1):
    path = BASE_DATA_PATH +'shard_' + str(i)
    try:
      os.makedirs(path)
    except:
      print "exists ", path
    shard = Popen([mongod, '--port', str(30000 + i), '--shardsvr', '--dbpath', path] + MONGOD_ARGS,
                  stdin=devnull, stdout=PIPE, stderr=STDOUT)
    shard.prefix = ascolor(MONGOD_COLOR, 'M' + str(i)) + ':'
    fds[shard.stdout] = shard
    procs.append(shard)
    waitfor(shard, 30000 + i)


#this must be done before starting mongos
for config_str in configs:
    host, port = config_str.split(':')
    config = pymongo.Connection(host, int(port)).config
    config.settings.save({'_id':'chunksize', 'value':CHUNK_SIZE}, safe=True)
del config #don't leave around connection directly to config server

if N_MONGOS == 1:
    MONGOS_PORT -= 1 # added back in loop

for i in range(1, N_MONGOS+1):
    router = Popen(VALGRIND_ARGS + [mongos, '--port', str(MONGOS_PORT+i), '--configdb' , ','.join(configs)] + MONGOS_ARGS,
                   stdin=devnull, stdout=PIPE, stderr=STDOUT)
    router.prefix = ascolor(MONGOS_COLOR, 'S' + str(i)) + ':'
    fds[router.stdout] = router
    procs.append(router)

    waitfor(router, MONGOS_PORT + i)

conn = pymongo.Connection('localhost', MONGOS_PORT + 1)
admin = conn.admin

for i in range(1, N_SHARDS+1):
    sleep(1.0)
    admin.command('addshard', 'localhost:'+str(30000+i), allowLocal=True)
    #admin.command('addshard', 'localhost:3000'+str(i), allowLocal=True)

AFTER_SETUP()

# just to be safe
sleep(2)

print '*** READY ***'
print 
print 

try:
    printer_thread.join()
except KeyboardInterrupt:
    pass



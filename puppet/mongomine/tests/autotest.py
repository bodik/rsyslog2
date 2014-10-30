#!/usr/bin/python2

import sys
import pymongo
from time import sleep
import random

try:
    # new pymongo
    from bson.son import SON
except ImportError:
    # old pymongo
    from pymongo.son import SON


MONGOS_PORT=27017

conn = pymongo.mongo_client.MongoClient('localhost', MONGOS_PORT)
autotest = conn.autotest
a = ('%06x' % random.randrange(16**6)).upper()

autotest.autotest.insert({"testdocument": a})
if autotest.autotest.find({"testdocument":a}).count() != 1:
	print "ERROR: autotest document not found"
	exit(1)
autotest.autotest.remove({"testdocument":a})

print "INFO: mongomine selftest passed"

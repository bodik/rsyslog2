#!/usr/bin/python
import urllib2
import socket
import time
import re
import datetime

import sys
###sys.path = ['/home/mongo/pyshared'] + sys.path
import pymongo

def douri(uri):
        try:
                #resp = requests.get(uri, timeout=120)
                f = urllib2.urlopen(uri,timeout=180)
                ret = {"uri": uri, "text":f.read()}
        except Exception, e:
                ret = {"uri": uri, "text":"error", "e":e}
                pass

        return ret

def ip2int(addr):
    return struct.unpack("!I", socket.inet_aton(addr))[0]
def int2ip(addr):
    return socket.inet_ntoa(struct.pack("!I", addr))



def fetch1():
        ret = []
        data = douri("https://check.torproject.org/cgi-bin/TorBulkExitList.py?ip=147.228.121.122")
        if data["text"] == "error":
                print "ERROR:", data
                return ret
        for tmp in data["text"].split("\n"):
                if not re.match("#",tmp):
                        ret.append({"source": data["uri"], "ip":tmp})
        return ret

def fetch2():
        ret = []
        data = douri("https://torstatus.blutmagie.de/ip_list_exit.php/Tor_ip_list_EXIT.csv")
        if data["text"] == "error":
                print "ERROR:", data
                return ret
        for tmp in data["text"].split("\n"):
                if not re.match("#",tmp):
                        ret.append({"source": data["uri"], "ip":tmp})
        return ret

def fetch3():
        ret = []
        data = douri("https://www.dan.me.uk/torlist/")
        if data["text"] == "error":
                print "ERROR:", data
                return ret
        for tmp in data["text"].split("\n"):
                if not re.match("#",tmp):
                        ret.append({"source": data["uri"], "ip":tmp})
        return ret


if __name__ == '__main__':

        data = fetch1() + fetch2() + fetch3()
        if data:
                connection_string = "mongodb://localhost"
                conn = pymongo.mongo_client.MongoClient(connection_string, safe=True, tz_aware=True)
                db = conn.tor

                for tmp in data:
                        if db.lists.find(tmp).count():
                                db.lists.update(tmp, { "$set": { "last": datetime.datetime.now()} }, upsert=True)
                        else:
                                tmp["first"] = datetime.datetime.now()
                                db.lists.insert(tmp)

                horizont = datetime.datetime.fromtimestamp(  time.time()- (60*60*24*60)  )
                db.lists.remove({"last": {"$lt": horizont}})


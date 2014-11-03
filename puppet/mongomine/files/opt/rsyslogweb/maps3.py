import pymongo
import bson
import sys
import time
import datetime
import itertools
import os
from bson import SON

import pprint
pp = pprint.PrettyPrinter(indent=4)
def printf(format, *args):
    sys.stdout.write(format % args)




#takhle naivne to delat nejde, rozhazuje to casove zony
#emit_mapHourly = "var d = new Date(this.t).getTime(); var a = new Date(); a.setTime(d-(d% (60*60 *1000) ));"
#emit_remapDaily = """
#        var d = new Date(this._id.t).getTime();
#        var a = new Date();
#        a.setTime(d-(d% (60*60*24*1000) ));
#"""

# musi to byt takhle i kdyz mam zmereno ze to je pomalejsi
emit_mapHourly = """var a = new Date(
            this.t.getFullYear(),
            this.t.getMonth(),
            this.t.getDate(),
            this.t.getHours(),
            0, 0, 0);"""
emit_mapDaily = """var a = new Date(
            this.t.getFullYear(),
            this.t.getMonth(),
            this.t.getDate(),
            0, 0, 0, 0);"""
emit_mapMonthly = """var a = new Date(
            this.t.getFullYear(),
            this.t.getMonth(),
            1, 0, 0, 0, 0);"""

emit_remapDaily = """var a = new Date(
            this._id.t.getFullYear(),
            this._id.t.getMonth(),
            this._id.t.getDate(),
            0, 0, 0, 0);"""
emit_remapMonthly = """
        var a = new Date(
            this._id.t.getFullYear(),
            this._id.t.getMonth(),
            1, 0, 0, 0, 0);
"""

emit_passTime = "var a = this._id.t;"



reducef = bson.Code("""
	function(k,v) {
	    var r = { count:0 } ;
	    v.forEach(function(v)
	        { r.count+=v.count });
	    return r;}
	""")


def reduceCount(src, mapf, outname, query=None, out=None):
	if out is None:
		out = {"replace":outname}

	print("INFO: reduceCount:",{"src":src, "outname": outname, "map":mapf, "reduce":reducef, "query":query, "out": out})

	timestart = time.time()
	ret = db[src].map_reduce(mapf, reducef, query=query, out=out )
	timestop = time.time()

	if( isinstance(ret, pymongo.collection.Collection) ):
		ret = "OK"
	else:
		ret = "FAIL"
	
	printf("INFO: reduceCount: time %d\n",(timestop-timestart))
	db.timingReduces.update(
		{"name": outname},
		{ "name": outname,
		  "created": timestart,
		  "finished": timestop,
		  "took": timestop-timestart,
		  "ret": ret
		},
		upsert=True
	)
	

# the point is to generate map function which has 
#  %s for time computing
#  emiting header
#  list of emited fields .. project
#  emiting footer/counter
# to be able to generate map function dynamically and be able to cascade/chain maps
def genmap(keys):
	ret = []
	ret.append("""
		function() { 
                        %s
                        emit({ t: a,
		""")

	for tmp in keys:

		try:
			(prefix,fname) = tmp.split(".")
		except:
			prefix = ""
			fname = tmp

		ret.append("""%s: (this.%s ? this.%s.toString() : 'NULL'),""" % (fname, tmp, tmp) )

	ret.append("""
			},{count: (this.value ? this.value.count : 1)});
		}
		""")

	return "\n".join(ret)



def make_timedmap(source, columns, maptime, destination, query=None, out=None):
	mapf = bson.Code(
		genmap(columns) % maptime
		)
	reduceCount(source, mapf, destination, query, out)







# snazil jsem se to nastavit stejne jako sshcrackerm.pl
#  pokud nekdo za 1 den prekroci limit 20 failu je povazovan za zlouna
#  zlouni se cachuji 14 dni v cache/banned.txt
#TODO: bylo by dobre udelat nejaky testcase na spravnost dotazovani na cas :(
def make_mapCrackers():
	mapf = bson.Code("""
			function() {
			        emit(
			                {remote: (this._id.remote ? this._id.remote.toString() : 'NULL'),
			                 result: (this._id.result ? this._id.result.toString() : 'NULL')}, 
			                { count: this.value.count });
			}""")
	horizont = datetime.datetime.fromtimestamp(  time.time()- (60*60*24*14)  ) 
	query = { 
####		"_id.t": {"$gte": horizont },
		"_id.result" : { "$not": { "$in": ["Accepted", "Authorized", "NULL"] }},
                "value.count": { "$gt": 20 }
		}

	reduceCount("mapRemoteResultPerDay", mapf, "mapCrackers", query)




############################ MAIN

# lock cron mutex
lock_path = "/tmp/rsyslogweb-maps.lock"
if os.path.exists(lock_path):
	print "lockfile exists. not running"
	exit(1)
else:
	file = open(lock_path, 'w')
	file.write('')
	file.close()



connection = pymongo.mongo_client.MongoClient("mongodb://localhost", safe=True)
db = connection.sshd
log = db.log





# vezmu si teda nove dokumenty ktere pritelky
# TODO: tohle jde asi predelat na find and save, bylo by to asi snazsi ...
query = dict()

printf("INFO: generating work\n")
#minimalne pro bootstrap map tady musi byt nejaka omezena zelva jinak generovani map spatne
begin = db.internalData.find_one({"type": "reduce", "name": "log"})
if begin:
	query["_id"] = dict()
        query["_id"]["$gt"] = begin["last_reduced_id"]

#tady si musim ukousnout nejakou praci
step = 300000
c = db.log.find(query, {"_id":1}).sort("_id", direction=1).limit(step)
count = c.count(with_limit_and_skip=True)
printf("DEBUG: count=%d\n",count)
end = None
if count>0:
	#sebrat posledni prvek v batchi kvuli ID
        end = next(c.skip(count-1), None)
	printf("DEBUG: end=")
	print end

if end:
	if not "_id" in query:
		query["_id"] = dict()
        query["_id"]["$lte"] = end["_id"]
	db.internalData.update({"type": "reduce", "name": "log"}, {"$set": {"last_reduced_id":end["_id"]}}, upsert=True)
printf("INFO: work found, count=%d\n", count)




# a zredukuju je, vysledek pripocitam k existujici mape

make_timedmap( "log", [], emit_mapHourly, "mapLogPerHour", query, {"reduce":"mapLogPerHour"} )
# mapLogPerX, grap_mapLogPerX
make_timedmap( "mapLogPerHour", [], emit_remapDaily, "mapLogPerDay" )
make_timedmap( "mapLogPerDay",	[], emit_remapMonthly, "mapLogPerMonth" )



query["@tags"] = { "$not": {"$in": ["_grokparsefailure"]}} 

make_timedmap( 
	"log", 
	["logsource", "user", "method", "remote", "result"], 
	emit_mapHourly, 
	"mapLogsourceUserMethodRemoteResultPerHour", 
	query, 
	SON([("reduce", "mapLogsourceUserMethodRemoteResultPerHour"), ("sharded", True)])
)


# mapLogsourceUserMethodRemoteResultPerX
make_timedmap( 
	"log", 
	["logsource", "user", "method", "remote", "result"], 
	emit_mapDaily,
	"mapLogsourceUserMethodRemoteResultPerDay",
	query,
	SON([("reduce", "mapLogsourceUserMethodRemoteResultPerDay"), ("sharded", True)])
)

make_timedmap( 
	"log", 
	["logsource", "user", "method", "remote", "result"], 
	emit_mapMonthly,
	"mapLogsourceUserMethodRemoteResultPerMonth",
	query,
	SON([("reduce", "mapLogsourceUserMethodRemoteResultPerMonth"), ("sharded", True)])
)


# mapRemoteResultPerX - remote profile, graph_RemoteResultPerX
#for per in ["PerHour", "PerDay", "PerMonth"]:
#	make_timedmap( "mapLogsourceUserMethodRemoteResult"+per, ["_id.remote","_id.result"], emit_passTime, "mapRemoteResult"+per )

make_timedmap( 
	"log", 
	["remote","result"], 
	emit_mapHourly, 
	"mapRemoteResultPerHour",
	query,
	{"reduce": "mapRemoteResultPerHour"} 
)
make_timedmap( 
	"log", 
	["remote","result"], 
	emit_mapDaily, 
	"mapRemoteResultPerDay",
	query,
	{"reduce": "mapRemoteResultPerDay"} 
)
make_timedmap( 
	"log", 
	["remote","result"], 
	emit_mapMonthly, 
	"mapRemoteResultPerMonth",
	query,
	{"reduce": "mapRemoteResultPerMonth"} 
)



# mapRemoteResult - remote profile
mapf = bson.Code("""function(){ emit(
                        { remote: (this._id.remote ? this._id.remote.toString() : 'NULL'),
                          result: (this._id.result ? this._id.result.toString() : 'NULL') },
                        { count: this.value.count }
                    );}""")
reduceCount("mapRemoteResultPerMonth", mapf, "mapRemoteResult")


# mapResultPerX - graph_ResultPerX
for per in ["PerHour", "PerDay", "PerMonth"]:
	make_timedmap( "mapRemoteResult"+per, ["_id.result"], emit_passTime, "mapResult"+per)


# mapResult - table_mapResult, search results field
mapf = bson.Code("""function(){ emit( 
			{ result: (this._id.result ? this._id.result.toString() : 'NULL') },
			{ count: this.value.count }
                    );}	""")
reduceCount("mapResultPerMonth", mapf, "mapResult")



# mapMethod - search methods field
#mapf = bson.Code("""function(){ emit( 
#			{ method: (this._id.method ? this._id.method.toString() : 'NULL') },
#			{ count: this.value.count }
#                    );}	""")
#reduceCount("mapLogsourceUserMethodRemoteResultPerMonth", mapf, "mapMethod")
mapf = bson.Code("""function(){ emit( 
			{ method: (this.method ? this.method.toString() : 'NULL') },
			{count: (this.value ? this.value.count : 1)}
                    );}	""")
reduceCount("log", mapf, "mapMethod", query, {"reduce": "mapMethod"})



make_mapCrackers()

#except:
#    print "Error trying to read collection:" + pp.pprint(sys.exc_info())

# unlock cron mutex
os.unlink(lock_path)


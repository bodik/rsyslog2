#!/bin/sh


#defaults
if [ -d /var/cache/nfdump/ ]; then
	FILE="/var/cache/nfdump/$(ls /var/cache/nfdump/ -1 | tail -2 | head -1)"
else
	FILE="/tmp/nonexistentfile"
fi
TZ=$(date +%z)
HEADER=0

while getopts "f:v" o; do
	case "${o}" in
		f)
			FILE=${OPTARG}
		;;
		z)
			TZ=${OPTARG}
		;;
		v)
			HEADER="1"
		;;
	esac
done

FNAME=$(basename $FILE)


#toto by bylo spravne, az na static 
# nf_common.c: void String_DstPort(master_record_t *r, char *string) {
#  ICMP_Port_decode(r, tmp);
#  takto se tam objevuji policka ktera tam nemaji byt, v policku s portem se zobrazi typ icmp ramce
#TR=$(echo $FNAME | sed 's/.*\([0-9]\{4\}\)\([0-9]\{2\}\)\([0-9]\{2\}\)\([0-9]\{2\}\)\([0-9]\{2\}\).*/\1-\2-\3 \4:\5:00/')
#nfdump -r $FILE -o "fmt:${TR},%ts,%te,%td,%sa,%da,%sp,%dp,%pr,%flg,%ipkt,%ibyt,%in" -q | sed 's/,[ ]\+/,/g'| sed 's/[ ]\+,/,/g'


#a takto se to musi delat s defaulnim nfdumpem 
# ndfump -o csv dava tyto policka, nas ale zajimaji pouze nektere polozky
# ts,te,td,sa,da,sp,dp,pr,flg,fwd,stos,ipkt,ibyt,opkt,obyt,in,out,sas,das,smk,dmk,dtos,dir,nh,nhb,svln,dvln,ismc,odmc,idmc,osmc,mpls1,mpls2,mpls3,mpls4,mpls5,mpls6,mpls7,mpls8,mpls9,mpls10,ra,eng
# ts,te,td,sa,da,sp,dp,pr,flg,ipkt,inbyt,in

# policko flow_received se musi pridat rucne protoze v datagramech se bere flowset.unixtime v ulozenych souborech ale neni
RECEIVED=$(echo $FNAME | sed 's/.*\([0-9]\{4\}\)\([0-9]\{2\}\)\([0-9]\{2\}\)\([0-9]\{2\}\)\([0-9]\{2\}\).*/\1-\2-\3 \4:\5:00/')

if [ $HEADER -eq 1 ]; then
	echo "ts,te,td,sa,da,sp,dp,pr,flg,fwd,stos,ipkt,ibyt,opkt,obyt,in,out,sas,das,smk,dmk,dtos,dir,nh,nhb,svln,dvln,ismc,odmc,idmc,osmc,mpls1,mpls2,mpls3,mpls4,mpls5,mpls6,mpls7,mpls8,mpls9,mpls10,ra,eng" | \
	awk -v A="tr" -v TZ="" -F"," '{print A TZ"," $1 TZ"," $2 TZ"," $3 "," $4 "," $5 "," $6 "," $7 "," $8 "," $9 "," $12 "," $13 "," $16}'
fi


nfdump -r $FILE -o csv -q 2>/dev/null | grep -v "No matched flows" | \
awk -v A="$RECEIVED" -v TZ="$TZ" -F"," '{print A TZ"," $1 TZ"," $2 TZ"," $3 "," $4 "," $5 "," $6 "," $7 "," $8 "," $9 "," $12 "," $13 "," $16}'

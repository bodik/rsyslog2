
if [ -z $1 ]; then
	SEND="../../data/nfcapd.201406120125-anon"
else
	SEND=$1
fi

FNAME=$(basename $SEND)

#toto by bylo spravne, az na static 
# nf_common.c: void String_DstPort(master_record_t *r, char *string) {
#  ICMP_Port_decode(r, tmp);
#TR=$(echo $FNAME | sed 's/.*\([0-9]\{4\}\)\([0-9]\{2\}\)\([0-9]\{2\}\)\([0-9]\{2\}\)\([0-9]\{2\}\).*/\1-\2-\3 \4:\5:00/')
#./nfdump -r $SEND -o "fmt:${TR},%ts,%te,%td,%sa,%da,%sp,%dp,%pr,%flg,%ipkt,%ibyt,%in" -q | sed 's/,[ ]\+/,/g'| sed 's/[ ]\+,/,/g'

#a takto se to musi delat s defaulnim nfdumpem 
RED=$(echo $FNAME | sed 's/.*\([0-9]\{4\}\)\([0-9]\{2\}\)\([0-9]\{2\}\)\([0-9]\{2\}\)\([0-9]\{2\}\).*/\1-\2-\3/')
RET=$(echo $FNAME | sed 's/.*\([0-9]\{4\}\)\([0-9]\{2\}\)\([0-9]\{2\}\)\([0-9]\{2\}\)\([0-9]\{2\}\).*/\4:\5:00/')
./nfdump -r $SEND -o csv -q | \
awk -v RED="$RED" -v RET="$RET" -F"," '{print RED,RET "," $1 "," $2 "," $3 "," $4 "," $5 "," $6 "," $7 "," $8 "," $9 "," $12 "," $13 "," $16}'

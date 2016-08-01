
if [ -z $1 ]; then
	echo "ERROR: no dir"
	exit 1
fi
DIR=$1

if [ -z $2 ]; then
	DEST=esb.metacentrum.cz
else
	DEST=$2
fi

if [ -z $3 ]; then
	PORT=49558
else
	PORT=$3
fi

echo -n "INFO: du "
du -sh $DIR
BEGIN=`date +%s`
echo "BEGIN: $DIR"

(find $DIR -type f ! -name "*7z" -exec cat {} \; ; find $DIR -type f -name "*7z" -exec 7z -so x {} 2>/dev/null \;) | grep "modules:" |pv | nc -q3 $DEST $PORT

END=`date +%s`
TIME=$(($END-$BEGIN))
echo "END: $DIR in ${TIME}s"

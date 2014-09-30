if [ -z $1 ]; then
	SPAN=3
else
	SPAN=$1
fi

A=`python el_listindex.py | rev | awk '{print $1}' | rev | sed 's/}//' | awk 'BEGIN{I=0} //{I+=$0} END{print I;}'`
sleep $SPAN;
B=`python el_listindex.py | rev | awk '{print $1}' | rev | sed 's/}//' | awk 'BEGIN{I=0} //{I+=$0} END{print I;}'`

if [ -z $B ]; then
	A=0
fi
if [ -z $B ]; then
	B=0
fi
SPEED=$((($B-$A)/$SPAN))

echo "ELS incoming speed: $SPEED"
#python graphiteit.py els.incoming_speed $SPEED
#python graphiteit.py els.total_docs $B


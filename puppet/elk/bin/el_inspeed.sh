#!/bin/sh

if [ -z $1 ]; then
	SPAN=3
else
	SPAN=$1
fi

A=$(curl -s http://localhost:39200/_cat/indices | awk '{print $6}' | awk 'BEGIN{I=0} //{I+=$0} END{print I;}')
sleep $SPAN;
B=$(curl -s http://localhost:39200/_cat/indices | awk '{print $6}' | awk 'BEGIN{I=0} //{I+=$0} END{print I;}')

if [ -z $B ]; then
	A=0
fi
if [ -z $B ]; then
	B=0
fi
SPEED=$((($B-$A)/$SPAN))

echo "ELS incoming speed: $SPEED"

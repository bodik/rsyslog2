top -H -p $1
echo -n "thread:"
read A
#sisel
jstack $1 | grep -A10 nid=`printf "0x%x\n" $A`


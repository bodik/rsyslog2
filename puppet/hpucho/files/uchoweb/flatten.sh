#wget -m -l3 -r --http-user tomcat --http-passwd tomcat localhost:8080/manager
#wget --no-parent -e robots=off -m -l3 -r --http-user tomcat --http-passwd tomcat http://localhost:8080/manager/

mkdir OUTPUT
for all in `find . -type f`; do
	T=$(echo $all | sed 's/\.\///' | sed 's/\//AAAA/g' | sed 's/\?/BBBB/g')
	cp $all OUTPUT/$T
done

for all in `ls OUTPUT/*.1`; do 
	T=$(echo $all | sed 's/\.1$//')
	mv $all $T
done

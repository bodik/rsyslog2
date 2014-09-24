
cat << __EOF__

translate {
	field => "[nf][protocol]"
	destination => "[nf][pr]"
	dictionary => [
__EOF__

wget http://www.iana.org/assignments/protocol-numbers/protocol-numbers.txt -O - 2>/dev/null | egrep '  [0-9]+ +[a-zA-Z]' | awk '{print "\""$1"\",\""$2"\","}'

cat << __EOF__
	]
}
__EOF__


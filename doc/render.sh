BIN=$(gem contents github-markdown | grep bin/gfm)

if [ ! -f $BIN ]; then
	echo "ERROR: gfm not found"
	exit 1
fi

for all in $(find . -name "*md"); do
	$BIN $all > $all.html
done

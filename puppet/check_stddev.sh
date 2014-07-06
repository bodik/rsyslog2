for all in $(find . -maxdepth 2 -type f -name "*.check.sh"); do
	sh $all
done

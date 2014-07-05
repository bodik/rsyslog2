for all in $(find . -maxdepth 1 -type f -name "*.check.sh"); do
	sh $all
done

#will grab last field from tester and cound avg from the data
rev | awk '{print $1}' | rev | sed 's/}//' | awk '{ sum += $1 } END { if (NR > 0) print sum / NR }'

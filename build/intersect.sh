#!/bin/bash

if [[ -z $1 ]] || [[ -z $2 ]]; then
	echo "Usage: ./intersect.sh <db1.meryl> <db2.meryl> [out]"
	echo "Get <db1>_and_<db2>.meryl. Counts will be set as found in <db1.meryl>"
	echo "<db1>_and_<db2>.meryl will be linked as [out].meryl"
	exit -1
fi

db1=$1
db2=$2
out=$3

db1=${db1/.meryl/}
db2=${db2/.meryl/}

if [[ ! -d "${db1}_and_${db2}.meryl" ]]; then
	echo "\
	meryl intersect output ${db1}_and_${db2}.meryl $db1.meryl $db2.meryl"
	meryl intersect output ${db1}_and_${db2}.meryl $db1.meryl $db2.meryl
	echo
fi

ln -s ${db1}_and_${db2}.meryl $out.meryl




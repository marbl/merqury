#!/bin/bash

if [[ -z $1 ]] || [[ -z $2 ]]; then
	echo "Usage: ./diff.sh <db1.meryl> <db2.meryl> [out] [-no-filt]"
	echo "Get <db1>_only.meryl and <db2>_only.meryl and filter with filt.sh"
	echo "[out] is passed to filt.sh for linking the final filtered meryl db"
  echo "[-no-filt] skips the filtering step"
	exit -1
fi

db1=$1
db2=$2
if ! [[ "$3" == "-no-filt" ]]; then
  out=$3
fi
if [[ ${@: -1} == "-no-filt" ]]; then
  skip_filt=1
fi

db1=${db1/.meryl/}
db2=${db2/.meryl/}

if [ ! -d ${db1}_not_${db2}.meryl ]; then
	echo "\
	meryl difference output ${db1}_not_${db2}.meryl $db1.meryl $db2.meryl"
	meryl difference output ${db1}_not_${db2}.meryl $db1.meryl $db2.meryl
	echo
fi

if [[ $skip_filt -eq 1 ]]; then
  echo "Skip filtering.
  ln -s ${db1}_not_${db2}.meryl $out.meryl"
  ln -s ${db1}_not_${db2}.meryl $out.meryl
else
  echo "\
  bash $MERQURY/build/filt.sh ${db1}_not_${db2}.meryl $out"
  bash $MERQURY/build/filt.sh ${db1}_not_${db2}.meryl $out
fi

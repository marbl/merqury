#!/usr/bin/env bash

if [ -z $1 ]; then
	echo "Usage: ./filt.sh <in.meryl> [out]"
	echo "Filter erroneous k-mers to get solid k-mers"
	echo "  <in.meryl>  meryl db to filter"
	echo "  [out]       link the final meryl db to this out.meryl"
	exit -1
fi

db=$1
db=${db/.meryl/}
out=$2

echo "Generate $db.hist"
meryl histogram $db.meryl > $db.hist

if [[ -s $db.hist.ploidy ]]; then
  echo -e "\nFound $db.hist.ploidy. Re-using it.\n"
else
  echo -e "\njava -jar -Xmx1g $MERQURY/eval/kmerHistToPloidyDepth.jar $db.hist > $db.hist.ploidy"
  java -jar -Xmx1g $MERQURY/eval/kmerHistToPloidyDepth.jar $db.hist > $db.hist.ploidy
fi

cat $db.hist.ploidy

filt=`cat $db.hist.ploidy | grep -v "warning" | sed -n 2p | awk '{print $NF}'`

echo "
Filter out kmers <= $filt"

echo "
meryl greater-than $filt output $db.gt$filt.meryl $db.meryl"
meryl greater-than $filt output $db.gt$filt.meryl $db.meryl
echo $filt > $db.filt

if [[ "$out" = "" ]]; then
  echo -e "\nDone: $db.gt$filt.meryl"
  exit 0
fi

echo "
Link the final $db.gt$filt.meryl to $out.meryl"
ln -s $db.gt$filt.meryl $out.meryl


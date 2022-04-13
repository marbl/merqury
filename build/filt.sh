#!/usr/bin/env bash

if [ -z $1 ]; then
	echo "Usage: ./filt.sh <in.meryl> [out]"
	echo "Filter erroneous k-mers to get solid k-mers"
	echo -e "\t<in.meryl>:\tmeryl db to filter"
	echo -e "\t[out]:\tlink the final meryl db to this out.meryl"
	exit -1
fi

db=$1
db=${db/.meryl/}
out=$2

echo "Generate $db.hist"
meryl histogram $db.meryl > $db.hist

echo "
java -jar -Xmx1g $MERQURY/eval/kmerHistToPloidyDepth.jar $db.hist
"
java -jar -Xmx1g $MERQURY/eval/kmerHistToPloidyDepth.jar $db.hist > $db.hist.ploidy

cat $db.hist.ploidy

filt=`sed -n 2p $db.hist.ploidy | awk '{print $NF}'`

echo "
Filter out kmers <= $filt"

echo "
meryl greater-than $filt output $db.gt$filt.meryl $db.meryl
"
meryl greater-than $filt output $db.gt$filt.meryl $db.meryl
echo $filt > $db.filt

if [[ "$out" = "" ]]; then
    exit 0
fi

echo "
Link the final $db.gt$filt.meryl to $out.meryl"
ln -s $db.gt$filt.meryl $out.meryl


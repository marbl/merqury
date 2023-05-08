#!/usr/bin/env bash
if [ -z $1 ]; then
	echo "Usage: ./_union_sum.sh <k-size> <meryl.list> <output_prefix>"
	echo -e "Merge <meryl.list>"
	echo -e "<k-size>: k-mer size used to build meryl dbs in <meryl.list>"
	echo -e "<meryl.list>: list of meryl dbs to merge"
	echo -e "<output_prefix>: final merged meryl db. <output_prefix>.meryl will be generated."
	exit -1
fi

set -o pipefail
set -e

k=$1
input_fofn=$2
output_prefix=$3.k$k

## Collect .meryl files
LEN=`wc -l $input_fofn | awk '{print $1}'`
NUM_DBS_TO_JOIN=100	# Join every $NUM_DBS_TO_JOIN as intermediates, then merge at the end
JOIN_IDX=0

## If there is only 1 input, no need to run meryl union-sum
if [ $LEN -eq 1 ]; then
  echo "Only one input meryl db detected. Rename and exit."
  meryl=`cat $input_fofn`
  mv $meryl $output_prefix.meryl
  meryl histogram $output_prefix.meryl > $output_prefix.hist
  echo "Use $output_prefix.hist for genomescope etc."
  echo "Done!"
  exit 0
fi


echo "Set ulimit: ulimit -Sn 32000"
ulimit -Sn 32000

for FROM_IDX in $(seq 1 $NUM_DBS_TO_JOIN $LEN)
do
	END_IDX=$((FROM_IDX+$NUM_DBS_TO_JOIN-1))
	if [ $END_IDX -gt $LEN ]; then
	    END_IDX=$LEN
	fi
	meryl=""
	for i in $(seq $FROM_IDX $END_IDX)
	do
	    input=`sed -n ${i}p $input_fofn`
	    if [ -d $input ]; then
        	meryl="$meryl $input"
	    fi
	done

	echo "union-sum of $FROM_IDX - $END_IDX :"

	JOIN_IDX=$((JOIN_IDX+1))
	output=${output_prefix}.$JOIN_IDX
	if [ ! -d $output ]; then
	    echo "
	    meryl \
	        k=$k \
	        union-sum \
	        output $output \
	        $meryl
	    "

	    meryl \
	        k=$k \
	        union-sum \
	        output $output \
	        $meryl || exit -1;
	fi
done

if [ $JOIN_IDX -gt $NUM_DBS_TO_JOIN ]; then
	echo -e "\tMore than $NUM_DBS_TO_JOIN intermediate files made."
	echo -e "\tRe run union_sum.sh on $output_prefix.*.meryl."
	exit 0
fi

if [ $JOIN_IDX -eq 1 ]; then
	echo "All inputs merged to $output_prefix.1. Renaming to $output_prefix.meryl"
	mv $output_prefix.1 $output_prefix.meryl
	echo "Done!"
	echo "
	meryl histogram $output_prefix.meryl > $output_prefix.hist
	"
	meryl histogram $output_prefix.meryl > $output_prefix.hist

	echo "Use $output_prefix.hist for genomescope etc."

	echo "Cleaning up"
	rm -r $meryl
	exit 0
fi

meryl=""
for i in $(seq 1 $JOIN_IDX)
do
    if [ -d $input ]; then
        meryl="$meryl $output_prefix.$i"
    fi
done

echo "union-sum of $output_prefix.[ 1 - $JOIN_IDX ] :"

if [ ! -d $output_prefix ]; then
    echo "
    meryl \
        k=$k \
        union-sum \
        output $output_prefix.meryl \
        $meryl
    "

    meryl \
        k=$k \
        union-sum \
        output $output_prefix.meryl \
        $meryl
fi

echo "
meryl histogram $output_prefix.meryl > $output_prefix.hist
"
meryl histogram $output_prefix.meryl > $output_prefix.hist

echo "Use $output_prefix.hist for genomescope etc."

echo "Done!"

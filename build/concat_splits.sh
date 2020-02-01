#!/bin/bash

echo "Usage: ./concat_splits.sh <k-size> <input.fofn> <out_prefix> [input2.fofn]"
echo "[input2.fofn]: Only needed for 10X data"

k=$1
input_fofn=$2
out_prefix=$3
input2_fofn=$4

if [[ -z $input_fofn ]] ; then
	echo "No <input.fofn> given. Exit."
	exit -1
fi

cat $input_fofn.* > $input_fofn.splits
if [[ ! -z $input2_fofn ]]; then
	cat $input2_fofn.* >> $input_fofn.splits
fi

echo "
$MERQURY/_submit_build.sh $k $input_fofn.splits $out_prefix"
$MERQURY/_submit_build.sh $k $input_fofn.splits $out_prefix

#!/usr/bin/env bash

echo "Usage: ./concat_splits.sh [-c] <k-size> <input.fofn> <out_prefix> [input2.fofn]"
echo -e "\t-c: OPTIONAL. homopolymer compress the sequence before counting kmers."
echo "[input2.fofn]: Only needed for 10X data"

if [ "x$1" = "x-c" ]; then
  compress="-c"
  shift
fi

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
$MERQURY/_submit_build.sh $compress $k $input_fofn.splits $out_prefix"
$MERQURY/_submit_build.sh $compress $k $input_fofn.splits $out_prefix

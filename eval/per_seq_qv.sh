#!/bin/bash

if [[ "$#" -lt 3 ]]; then
	echo "Usage: ./per_seq_qv.sh seq.fasta read.meryl out"
	echo ""
	echo "Get QV per seqIDs in seq.fasta"
	echo -e "seq.fasta:\tassembly, multi-fasta file"
	echo -e "read.meryl:\tk-mer counts of read set"
	echo -e "out:\toutput prefix"
	echo
	echo "Output will be generated as out.qv"
	echo "Arang Rhie, 2020-06-15. arrhie@gmail.com"
	echo
	exit 0
fi

seq=$1	# asm.fasta
read=$2	# read.meryl
name=$3	# output prefix

k=`meryl print $read | head -n 2 | tail -n 1 | awk '{print length($1)}'`
echo "Detected k-mer size $k"
echo

seq_name=`echo $seq | sed 's/.fasta$//g' | sed 's/.fa$//g'`


if [[ ! -e $seq_name.0.meryl ]]; then

	if [[ ! -e $seq_name.meryl ]]; then
		echo "# No $seq_name.meryl found. Counting ${k}-mers..."
		meryl count k=$k output $seq_name.meryl $seq
		echo
	fi
	echo "# Collect k-mers found in $seq_name only"
	meryl difference $seq_name.meryl $read output $seq_name.0.meryl
	echo
fi

echo "QV per sequences"
meryl-lookup -existence -sequence $seq -mers $seq_name.0.meryl/ | \
   awk -v k=$k '{print $1"\t"$4"\t"$2"\t"(-10*log(1-(1-$4/$2)^(1/k))/log(10))"\t"(1-(1-$4/$2)^(1/k))}' > $name.qv


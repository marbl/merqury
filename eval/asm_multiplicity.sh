#!/bin/bash

if [[ "$#" -lt 3 ]]; then
	echo "Usage: ./asm_multiplicity.sh <asm.fasta> <asm.meryl> <out>"
	echo -e "\t<asm.fasta>: assembly fasta file"
	echo -e "\t<asm.meryl>: assembly meryl dir"
	echo -e "\t<out>: output file prefix. <out>.copies.wig and <out>.asm_multiplicity.bigWig will be generated."
	exit 0
fi

asm_fa=$1
asm=$2
out=$3

# Requirements: samtools, ucsc kent utils
module load samtools
module load ucsc/396

if [[ ! -e $asm_fa ]]; then
	samtools faidx $asm_fa
fi


echo "
# Collect copy numbers in assembly"
meryl-lookup -wig-count -sequence $asm_fa -mers $asm > $out.copies.wig

echo "
# Convert to bigwig"
wigToBigWig $out.copies.wig $asm_fa.fai $out.asm_multiplicity.bigWig

echo "Done!"


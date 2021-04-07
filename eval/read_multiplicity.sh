#!/bin/bash

if [[ "$#" -lt 3 ]]; then
	echo "Usage: ./read_multiplicity.sh <asm.fasta> <read.meryl> <out>"
	echo -e "\t<asm.fasta>: assembly fasta file"
	echo -e "\t<read.meryl>: k-mer counts of the reads"
	echo -e "\t<out>: output file prefix. <out>.read.wig and <out>.read_multiplicity.bigWig will be generated."
	exit 0
fi

asm_fa=$1
read=$2
out=$3
asm=`echo $asm_fa | sed 's/.gz$//g' | sed 's/.fasta$//g' | sed 's/.fa$//g'`

module load samtools
module load ucsc/396

if [[ ! -e $asm_fa.fai ]]; then
	samtools faidx $asm_fa
fi

echo "
# Collect k-mer multiplicity in reads"
meryl-lookup -wig-count -sequence $asm_fa -mers $read > $out.read.wig

echo "
# Convert to bigwig"
wigToBigWig $out.read.wig $asm_fa.fai $out.read_multiplicity.bigwig


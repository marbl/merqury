#!/bin/sh

if [[ "$#" -lt 2 ]]; then
	echo "Usage: ./asm_multiplicity.sh <asm.fasta> <out>"
	echo -e "\t<asm.fasta>: assembly fasta file"
	echo -e "\t<out>: output file prefix. <out>.copies.wig and <out>.asm_multiplicity.bigWig will be generated."
	exit 0
fi

asm_fa=$1
out=$2
asm=`echo $asm_fa | sed 's/.gz$//g' | sed 's/.fasta$//g' | sed 's/.fa$//g'`

# Requirements: samtools, ucsc kent utils
module load samtools
module load ucsc/396

if [[ ! -e $asm_fa ]]; then
	samtools faidx $asm_fa
fi

echo "
# Collect copy numbers in assembly"
meryl-lookup -dump -memory 12 -sequence $asm_fa -mers $asm.meryl | awk '$4=="T"' | java -jar -Xmx1g $MERQURY/util/merylDumpToWig.jar - > $out.copies.wig

echo "
# Convert to bigwig"
wigToBigWig $out.copies.wig $asm_fa.fai $out.asm_multiplicity.bigWig

echo "Done!"


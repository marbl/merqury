#!/bin/bash

if [[ $# -lt 4 ]]; then
	echo "Usage: ./exclude_reads.sh <in.meryl> <R1.fastq.gz> <R2.fastq.gz> <out.prefix>"
	echo "When a read has a k-mer in <in.meryl>, both pairs will be excluded."
	echo -e "\t<in.meryl>   : meryl db to lookup"
	echo -e "\t<R1.fastq.gz>: read 1 fastq file."
	echo -e "\t<R2.fastq.gz>: read 2 fastq file."
	echo -e "\t<out.prefix> : <out.prefix>.R1.fastq.gz and <out.prefix>.R2.fastq.gz will be generated."
	exit -1
fi

meryl=$1
read1=$2
read2=$3
out=$4

echo "
meryl-lookup -memory 2 -exclude -mers $meryl -sequence $read1 -sequence2 $read2 -r2 $out.R2.fastq.gz | pigz -c > $out.R1.fastq.gz"
meryl-lookup -memory 2 -exclude -mers $meryl -sequence $read1 -sequence2 $read2 -r2 $out.R2.fastq.gz | pigz -c > $out.R1.fastq.gz


#!/bin/bash

if [[ $# -lt 3 ]]; then
	echo "Usage: ./exclude_reads.sh <in.meryl> <input.map> <out.prefix> [-10x] [num_line]"
	echo "When a read has a k-mer in <in.meryl>, both pairs will be excluded."
	echo -e "\t<in.meryl>   : meryl db to lookup"
	echo -e "\t<input.map>  : <R1.fastq.gz> <tab> <R2.fastq.gz>"
	echo -e "\t<out.prefix> : <out.prefix>.R1.fastq.gz and <out.prefix>.R2.fastq.gz will be generated."
  echo -e "\t[-10x]       : set this if the first 23 bp in every R1 should be ignored."
  echo -e "\t[num_line]   : n'th line of the input.map will be processed."
	exit -1
fi

meryl=$1
input=$2
out=$3
opt=$4

if [[ "$opt" == "-10x" ]]; then
  i=$5
fi


if [[ "$opt" != "-10x" ]]; then
  opt=""
  i=$4
fi

if [[ -z $i ]]; then
  i=$SLURM_ARRAY_TASK_ID
fi

if [[ -z $i ]]; then
  echo "provide the line num to proceed from the input.map"
  exit -1
fi

read1=`sed -n ${i}p $input | awk '{print $1}'`
read2=`sed -n ${i}p $input | awk '{print $2}'`

out_1=${out}/$read1
out_2=${out}/$read2
if [[ -z $read2 ]]; then
  out_2=""
fi

echo "
meryl-lookup -exclude $opt -sequence $read1 $read2 -mers $meryl -output ${out_1} ${out_2}
"
meryl-lookup -exclude $opt -sequence $read1 $read2 -mers $meryl -output ${out_1} ${out_2}



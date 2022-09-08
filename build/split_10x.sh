#!/usr/bin/env bash

echo "Usage: ./split_10x.sh <input.fofn> [LINE_NUM]"
echo -e "\t<input.fofn>: 10XG fastq R1.gz files to split per 300 million lines."
echo -e "\t<input.fofn>.LINE_NUM will be generated."
echo -e "\t\tUse it for building meryl dbs. pigz will use maximum of 8 processes by default."
echo

FOFN=$1
if [ -z $FOFN ]; then
    echo "No <input.fofn> provided. Exit."
    exit -1
fi

tid=$SLURM_ARRAY_TASK_ID	# slurm environment variable for job arrays
LINE_NUM=$2

if [ -z $tid ]; then
    tid=$LINE_NUM
fi

if [ -z $tid ]; then
    echo "No SLURM_ARRAY_TASK_ID or LINE_NUM provided. Exit."
    exit -1
fi

cpus=$SLURM_CPUS_PER_TASK
if [[ -z $cpus ]]; then
    cpus=8
fi

fq=`sed -n ${tid}p $FOFN`
fq_prefix=`echo $fq | sed 's/.fastq.gz$//g' | sed 's/.fq.gz$//g' | sed 's/.fastq$//g' | sed 's/.fq$//g'`
fq_prefix=`basename $fq_prefix`

mkdir -p split

echo "
Strip off the first 23 basepairs (6 illumina library + 1 padding + 16 barcodes) and split the input file"

if [[ ${fq##*.} == "gz" ]]; then
	echo "\
	zcat $fq | awk '{if (NR%2==1) {print \$1} else {print substr(\$1,24)}}' | split -a 4 -d -l 300000000 --additional-suffix=.fq - split/$fq_prefix."
	zcat $fq | awk '{if (NR%2==1) {print $1} else {print substr($1,24)}}' | split -a 4 -d -l 300000000 --additional-suffix=".fq" - split/$fq_prefix.
else
	echo "\
	cat $fq | awk '{if (NR%2==1) {print \$1} else {print substr(\$1,24)}}' | split -a 4 -d -l 300000000 --additional-suffix=.fq  - split/$fq_prefix."
	cat $fq | awk '{if (NR%2==1) {print  $1} else {print substr($1,24)}}' | split -a 4 -d -l 300000000 --additional-suffix=".fq" - split/$fq_prefix.
fi

echo "
pigz --processes $cpus split/$fq_prefix.*.fq"
pigz --processes $cpus split/$fq_prefix.*.fq

ls split/$fq_prefix.[0-9][0-9][0-9][0-9].fq.gz > $FOFN.$tid
LEN=`wc -l $FOFN.$tid | awk '{print $1}'`

echo "Splitting done: $LEN files generated."


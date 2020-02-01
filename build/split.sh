#!/bin/bash

echo "Usage: ./split.sh <input.fofn> [LINE_NUM]"
echo -e "\t<input.fofn>: fastq.gz files we want to split by every 300 million lines."
echo -e "\t<input.fofn>.LINE_NUM will be generated."
echo -e "\t\tUse it for building meryl dbs"
echo

FOFN=$1
if [ -z $FOFN ]; then
    echo "No <input.fofn> provided. Exit."
    exit -1
fi

tid=$SLURM_ARRAY_TASK_ID
LINE_NUM=$2

if [ -z $tid ]; then
    tid=$LINE_NUM
fi

if [ -z $tid ]; then
    echo "No SLURM_ARRAY_TASK_ID or LINE_NUM provided. Exit."
    exit -1
fi

cpus=$SLURM_CPUS_PER_TASK

fq=`sed -n ${tid}p $FOFN`
fq_prefix=`echo $fq | sed 's/.fastq.gz$//g' | sed 's/.fq.gz$//g' | sed 's/.fastq$//g' | sed 's/.fq$//g'`
fq_prefix=`basename $fq_prefix`

mkdir -p split

echo "
Splitting input file $fq"

if [[ ${fq##*.} == "gz" ]]; then
	echo "\
	zcat $fq | split -a 4 -d -l 300000000 --additional-suffix=.fq   - split/$fq_prefix."
	zcat $fq | split -a 4 -d -l 300000000 --additional-suffix=".fq" - split/$fq_prefix.
else
	echo "\
	split -a 4 -d -l 300000000 --additional-suffix=.fq   $fq split/$fq_prefix."
	split -a 4 -d -l 300000000 --additional-suffix=".fq" $fq split/$fq_prefix.
fi

echo "
pigz --processes $cpus split/$fq_prefix.*.fq"
pigz --processes $cpus split/$fq_prefix.*.fq

ls split/$fq_prefix.[0-9][0-9][0-9][0-9].fq.gz > $FOFN.$tid
LEN=`wc -l $FOFN.$tid | awk '{print $1}'`

echo "Splitting done: $LEN files generated."


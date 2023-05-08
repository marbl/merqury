#!/bin/bash

echo "Usage: ./split_ont_fa.sh <input.fofn> [LINE_NUM]"
echo -e "\t<input.fofn>: fasta.gz files we want to split by every 400 thousand lines."
echo -e "\t<input.fofn>.LINE_NUM will be generated."
echo -e "\tpigz will use maximum of 8 processes by default."
echo

FOFN=$1
if [ -z $FOFN ]; then
    echo "No <input.fofn> provided. Exit."
    exit -1
fi

tid=$SLURM_ARRAY_TASK_ID
LINE_NUM=$2
LINES_PER_FILE=400000 # ONT


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

fa=`sed -n ${tid}p $FOFN`
fa_prefix=`echo $fa | sed 's/\.gz$//g' | sed 's/\.fasta$//g' | sed 's/\.fa$//g'`
fa_prefix=`basename $fa_prefix`

mkdir -p split

echo "
Splitting input file $fa"
tmp=/lscratch/$SLURM_JOB_ID/split

mkdir -p $tmp

if [[ ${fa##*.} == "gz" ]]; then
	echo "\
	zcat $fa | split -a 4 -d -l $LINES_PER_FILE --additional-suffix=.fa   - $tmp/$fa_prefix."
	zcat $fa | split -a 4 -d -l $LINES_PER_FILE --additional-suffix=".fa" - $tmp/$fa_prefix.
else
	echo "\
	split -a 4 -d -l $LINES_PER_FILE --additional-suffix=.fa   $fa $tmp/$fa_prefix."
	split -a 4 -d -l $LINES_PER_FILE --additional-suffix=".fa" $fa $tmp/$fa_prefix.
fi

echo "
pigz --processes $cpus $tmp/$fa_prefix.*.fa"
pigz --processes $cpus $tmp/$fa_prefix.*.fa

echo "
mv $tmp/$fa_prefix.*.fa.gz split/"
mv $tmp/$fa_prefix.*.fa.gz split/

ls split/$fa_prefix.[0-9][0-9][0-9][0-9].fa.gz > $FOFN.$tid
LEN=`wc -l $FOFN.$tid | awk '{print $1}'`

echo "Splitting done: $LEN files generated."


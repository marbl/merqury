#!/bin/bash


if [[ -z $1 ]] || [[ -z $2 ]]; then
  echo "Usage: ./count.sh <k> <input.fofn> [offset line_num]"
  echo -e "\t<k>: k-size mers will be collected. REQUIRED."
  echo -e "\t<input.fofn>: list of fastq.gz file. Read pair 1 from 10X reads. REQUIRED."
  echo -e "\t[offset]: OPTIONAL. DEFAULT=0. For array job limit only."
  echo -e "\t[line_num]: OPTIONAL. (offset * 1000 + line_num)'th line of input.fofn will be the input."
  echo -e "\t\t\$SLURM_ARRAY_TASK_ID will be used if not specified."
  echo -e "\t*NOTE* This script is trimming off the first 23 bases before kmer counting. Only useful for 10X barcode trimming."
  exit -1
fi

k=$1
input_fofn=$2


if [ -z $3 ]; then
  offset=0
else
  offset=$3
fi

if [ ! -z $4 ]; then
  line_num=$4
else
  line_num=$SLURM_ARRAY_TASK_ID
fi

if [[ ! -z $SLURM_CPUS_PER_TASK ]]; then
  cpus="threads=$SLURM_CPUS_PER_TASK"
fi

# If SLURM_MEM_PER_NODE exist; give extra 4Gb
# otherwise, let meryl determine
if [[ ! -z $SLURM_MEM_PER_NODE ]]; then
  # Note: Provide memory in Gb unit. SLURM provides $SLURM_MEM_PER_NODE in Mb.
  # Give extra 4Gb to avoid 'Bus Error' form running out of memory.
  mem=$(((SLURM_MEM_PER_NODE/1024)-4))
  mem="memory=$mem"
fi

line_num=$(((offset * 1000) + $line_num))

# Read in the input path
input=`sed -n ${line_num}p $input_fofn`

# Name it accordingly
name=`echo $input | sed 's/.fastq.gz$//g' | sed 's/.fq.gz$//g' | sed 's/.fasta$//g' | sed 's/.fa$//g' | sed 's/.fasta.gz$//g' | sed 's/.fa.gz$//g'`
name=`basename $name`

output=$name.$k.$line_num.meryl

if [ ! -d $output ]; then
  # Run meryl count: Collect k-mer frequencies
  # Ignore the first 23 bases (6 Illumina library + 1 padding + 16 barcode bases)
  echo "
  zcat $input | awk '{if (NR%2==1) {print $1} else {print substr($1,24)}}' | meryl k=$k $cpus $mem count output $output -
  "
  zcat $input | awk '{if (NR%2==1) {print $1} else {print substr($1,24)}}' | meryl k=$k $cpus $mem count output $output -
else
  echo "$output dir already exist. Nothing to do with $name."
fi



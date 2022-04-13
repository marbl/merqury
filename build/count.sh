#!/usr/bin/env bash


if [[ -z $1 ]] || [[ -z $2 ]; then
    echo "Usage: ./count.sh [-c] <k> <input.fofn> [offset line_num]"
    echo -e "\t-c: OPTIONAL. homopolymer compress the sequence before counting kmers."
    echo -e "\t<k>: k-size mers will be collected. REQUIRED."
    echo -e "\t<input.fofn>: list of fastq / fasta file. REQUIRED."
    echo -e "\t[offset]: OPTIONAL. DEFAULT=0. For array job limit only."
    echo -e "\t[line_num]: OPTIONAL. (offset * 1000 + line_num)'th line of input.fofn will be the input."
    echo -e "\t\t\$SLURM_ARRAY_TASK_ID will be used if not specified."
    exit -1
fi

if [ "x$1" = "x-c" ]; then
  compress="compress"
  shift
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

#  Note: Provide memory in Gb unit. SLURM provides $SLURM_MEM_PER_NODE in Mb.
#            Give extra 4Gb to avoid 'Bus Error' form running out of memory.
if [[ -z $SLURM_MEM_PER_NODE ]]; then
  mem=28
else
  mem=$((SLURM_MEM_PER_NODE/1024))
fi
line_num=$(((offset * 1000) + $line_num))

# Read in the input path
input=`sed -n ${line_num}p $input_fofn`

# Name it accordingly
name=`echo $input | sed 's/.fastq.gz$//g' | sed 's/.fq.gz$//g' | sed 's/.fasta$//g' | sed 's/.fa$//g' | sed 's/.fasta.gz$//g' | sed 's/.fa.gz$//g'`
name=`basename $name`

output=$name.k$k.$line_num.meryl

if [ ! -d $output ]; then
# Run meryl count: Collect k-mer frequencies
echo "
meryl k=$k memory=$mem count $compress $input output $output
"
meryl k=$k memory=$mem count $compress $input output $output
else
echo "$output dir already exist. Nothing to do with $name."
fi



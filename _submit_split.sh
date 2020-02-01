#! /bin/bash

echo "Usage: ./_submit_split.sh <input.fofn>"
echo "Split the input.fofn for every 300 million lines"
echo -e "\t<input.fofn>: list of fastq(.gz) files"

if [ -z $1 ]; then
	echo "No input.fofn provided. Exit."
	exit -1
fi

LEN=`wc -l $1 | awk '{print $1}'`

cpus=6
mem=4g
name=split
script=$MERQURY/build/split.sh
args=$1
partition=norm
walltime=1-0
path=`pwd`
extra="--array=1-$LEN"

mkdir -p logs
if [ -z $extra ]; then
	log=logs/$name.%A.log
else
	log=logs/$name.%A_%a.log
fi

echo "\
sbatch -J $name --mem=$mem --partition=$partition --cpus-per-task=$cpus -D $path $extra --time=$walltime --error=$log --output=$log $script $args"
sbatch -J $name --mem=$mem --partition=$partition --cpus-per-task=$cpus -D $path $extra --time=$walltime --error=$log --output=$log $script $args


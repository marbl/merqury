#!/bin/bash

if [[ "$#" -lt 3 ]]; then
  echo "Usage: ./_submit_exclude.sh mat.meryl pat.meryl input.map"
  echo "  mat.meryl: maternal kmers to exclude. Output will have prefix as pat."
  echo "  pat.meryl: paternal kmers to exclude. Output will have prefix as mat."
  echo "  input.map: reads to filter"
  echo "    format: R1.fq.gz <tab> R2.fq.gz"
  exit -1
fi


LEN=`wc -l $3 | awk '{print $1}'`

cpus=4
mem=4g
name=filt
script=$MERQURY/trio/exclude_reads.sh
partition=norm
walltime=1-0
path=`pwd`
log=logs/$name.%A_%a.log
extra="--array=1-$LEN"

mkdir -p logs

db=$2
db=${db/.meryl/}
args="$1 $3 $db"

mkdir -p $db

echo "
sbatch -J $name --mem=$mem --partition=$partition --cpus-per-task=$cpus -D $path $extra --time=$walltime --error=$log --output=$log $script $args"
sbatch -J $name --mem=$mem --partition=$partition --cpus-per-task=$cpus -D $path $extra --time=$walltime --error=$log --output=$log $script $args

db=$1
db=${db/.meryl/}
args="$2 $3 $db"

mkdir -p $db

echo "
sbatch -J $name --mem=$mem --partition=$partition --cpus-per-task=$cpus -D $path $extra --time=$walltime --error=$log --output=$log $script $args"
sbatch -J $name --mem=$mem --partition=$partition --cpus-per-task=$cpus -D $path $extra --time=$walltime --error=$log --output=$log $script $args


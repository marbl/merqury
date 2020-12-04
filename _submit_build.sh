#!/bin/bash

build=$MERQURY/build

if [ -z $1 ]; then
    echo "Usage: ./_submit_meryl.sh <k-size> <input.fofn> <out_prefix> [mem=T]"
    echo -e "\t<k-size>: kmer size k"
    echo -e "\t<input.fofn>: ls *.fastq.gz > input.fofn. include both R1 and R2 for paired-end sequencing."
    echo -e "\t\taccepts fasta, fastq, gzipped or not."
    echo -e "\t<out_prefix>: Final merged meryl db will be named as <out_prefix>.meryl"
    echo -e "\t[mem=T]: Submit memory option on sbatch [DEFAULT=TRUE]. Set it to F to turn it off."
    exit 0
fi

k=$1
input_fofn=$2
out_prefix=$3
mem_opt=$4


LEN=`wc -l $input_fofn | awk '{print $1}'`

mkdir -p logs
offset=$((LEN/1000))
leftovers=$((LEN%1000))

cpus=16 # Max: 64 per each .meryl/ file writer
if [[ "$mem_opt" = "F" ]]; then
	mem=""
else
	mem="--mem=24g"
fi
name=$out_prefix.count
script=$build/count.sh
partition=quick
walltime=4:00:00
path=`pwd`
log=logs/$name.%A_%a.log

if [ -e meryl_count.jid ]; then
  echo "Removing meryl_count.jid"
  cat meryl_count.jid
  rm meryl_count.jid
fi

for i in $(seq 0 $offset)
do
  args="$k $input_fofn $i"
  if [[ $i -eq $offset ]]; then
      arr_max=$leftovers
  else
      arr_max=1000
  fi
  echo "\
  sbatch -J $name $mem --partition=$partition --cpus-per-task=$cpus -D $path --array=1-$arr_max --time=$walltime --error=$log --output=$log $script $args"
  sbatch -J $name $mem --partition=$partition --cpus-per-task=$cpus -D $path --array=1-$arr_max --time=$walltime --error=$log --output=$log $script $args | awk '{print $NF}' > meryl_count.jid
done

# Wait for these jobs
WAIT="afterok:"`cat meryl_count.jid | tr '\n' ',afterok:'`
WAIT=${WAIT%,}

## Collect .meryl list
if [ -e  meryl_count.meryl.list ]; then
  echo "Removing meryl_count.meryl.list"
  cat meryl_count.meryl.list
  rm  meryl_count.meryl.list
fi

for line_num in $(seq 1 $LEN)
do
  input=`sed -n ${line_num}p $input_fofn`
  name=`echo $input | sed 's/.fastq.gz$//g' | sed 's/.fq.gz$//g' | sed 's/.fasta$//g' | sed 's/.fa$//g' | sed 's/.fasta.gz$//g' | sed 's/.fa.gz$//g'`
  name=`basename $name`
  echo "$name.k$k.$line_num.meryl" >> meryl_count.meryl.list
done

cpus=16 # Max: 64 per each .meryl/ file writer
if [[ "$mem_opt" = "F" ]]; then
  mem=""
else
  mem="--mem=16g"
fi
walltime=2:00:00
partition=norm
name=$out_prefix.union_sum
script=$build/union_sum.sh
log=logs/$name.%A.log
args="$k meryl_count.meryl.list $out_prefix"
echo "\
sbatch -J $name $mem --partition=$partition --cpus-per-task=$cpus -D $path --dependency=$WAIT --time=$walltime --error=$log --output=$log $script $args"
sbatch -J $name $mem --partition=$partition --cpus-per-task=$cpus -D $path --dependency=$WAIT --time=$walltime --error=$log --output=$log $script $args | awk '{print $NF}' > meryl_union_sum.jid


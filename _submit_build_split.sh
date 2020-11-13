#!/bin/bash

build=$MERQURY/build

if [ -z $1 ]; then
  echo "Usage: ./_submit_meryl2_build.sh <k-size> <input.fofn> <out_prefix> [mem=T]"
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

# Split files when >12GB
cpus=20
if [[ "$mem_opt" = "F" ]]; then
  mem=""
else
  mem="--mem=4g"
fi
name=$out_prefix.split
script=$build/split.sh
partition=quick
walltime=4:00:00
path=`pwd`
log=logs/$name.%A_%a.log

wait_for=""
split=0

split_arrs=""

for i in $(seq 1 $LEN)
do
  fq=`sed -n ${i}p $input_fofn`
  GB=`du -k $fq  | awk '{printf "%.0f", $1/1024/1024}'`
  if [[ $GB -lt 15 ]]; then
    echo "$fq is $GB, less than 15GB. Skip splitting."
	  echo $fq >> $input_fofn.$i
	else
	  echo "$fq is $GB, over 15GB. Will split and run meryl in parallel."
	  echo "Split files will be in $input_fofn.$i"
	  args="$input_fofn"
	  split_arrs="$split_arrs$i,"
	  wait_for="${wait_for}afterok:$split_jid,"
	  split=1
	  echo
	fi
done

if [ $split -eq 1 ]; then
  split_arrs=${split_arrs%,}
  echo "
  sbatch -D $path -J $name --array=$split_arrs --partition=$partition $mem --cpus-per-task=$cpus --time=$walltime --error=$log --output=$log $script $args"
  sbatch -D $path -J $name --array=$split_arrs --partition=$partition $mem --cpus-per-task=$cpus --time=$walltime --error=$log --output=$log $script $args | awk '{print $NF}' > split_jid
  split_jid=`cat split_jid`
  wait_for="afterok:$split_jid"
  cpus=2
  if [[ "$mem_opt" = "F" ]]; then
    mem=""
  else
    mem="--mem=1g"
  fi
	name=$out_prefix.concat
	script=$build/concat_splits.sh
	args="$k $input_fofn $out_prefix"
	partition=quick
	walltime=10:00
	path=`pwd`
  log=logs/$name.%A.log
  wait_for="--dependency=${wait_for%,}"
  echo "
  sbatch -D $path -J $name --partition=$partition $mem --cpus-per-task=$cpus --time=$walltime $wait_for --error=$log --output=$log $script $args"
  sbatch -D $path -J $name --partition=$partition $mem --cpus-per-task=$cpus --time=$walltime $wait_for --error=$log --output=$log $script $args
  exit 0
else
  rm $input_fofn.*
  wait_for=""
fi

offset=$((LEN/1000))
leftovers=$((LEN%1000))

cpus=32 # Max: 64 per each .meryl/ file writer
if [[ "$mem_opt" = "F" ]]; then
  mem=""
else
  mem="--mem=32g"
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
  sbatch -J $name $mem --partition=$partition --cpus-per-task=$cpus -D $path --array=1-$arr_max --time=$walltime --error=$log --output=$log $script $args | awk '{print $NF}' >> meryl_count.jid
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
  echo "$name.$k.$line_num.meryl" >> meryl_count.meryl.list
done

cpus=48 # Max: 64 per each .meryl/ file writer
if [[ "$mem_opt" = "F" ]]; then
  mem=""
else
  mem="--mem=32g"
fi
walltime=4:00:00
partition=norm
name=$out_prefix.union_sum
script=$build/union_sum.sh
log=logs/$name.%A.log
args="$k meryl_count.meryl.list $out_prefix"
echo "\
sbatch -J $name $mem --partition=$partition --cpus-per-task=$cpus -D $path --dependency=$WAIT --time=$walltime --error=$log --output=$log $script $args"
sbatch -J $name $mem --partition=$partition --cpus-per-task=$cpus -D $path --dependency=$WAIT --time=$walltime --error=$log --output=$log $script $args | awk '{print $NF}' > meryl_union_sum.jid


#!/bin/bash


echo "Usage: ./hap_blob.sh <hap1.meryl> <hap2.meryl> <asm1.fasta> [asm2.fasta] <out>"

if [[ $# -lt 4 ]]; then
  exit -1
fi

source $MERQURY/util/util.sh

hap1=$1
hap2=$2
asm1=$3
asm2=$4
out=$5

if [[ -z $hap1 || -z $hap2 ]]; then
  echo "Check <hap1.meryl> and <hap2.meryl>."
  exit -1
fi

hap1=`link $hap1`
hap2=`link $hap2`

if [[ -z $asm1 ]]; then
  echo "No .fasta file given. Exit."
  exit -1
fi

asm1=`link $asm1`

if [[ -z $out ]]; then
  echo "No asm2 given."
  echo
  asm2=""
  out=$4
else
  asm2=`link $asm2`
fi

count=$out.hapmers.count
echo -e "Assembly\tContig\t${hap1/.meryl}\t${hap2/.meryl}\tSize" > $count
for asm in $asm1 $asm2
do
  name=`echo $asm | sed 's/.fasta$//g' | sed 's/.fa$//g' | sed 's/.fasta.gz$//g' | sed 's/.fa.gz$//g'`
  echo "
  Start processing $name"

  echo -e "\n\n--- Lookup k-mers in $hap1 and $hap2 ---"
  echo "
  meryl-lookup -existence -sequence $asm -mers $hap1 $hap2 | awk -v asm=$name '...' >> $count"
  meryl-lookup -existence -sequence $asm -mers $hap1 $hap2 |\
    awk -v asm=$name '{print asm"\t"$1"\t"$4"\t"$6"\t"$2}' >> $count
done

echo "
Plot hap-mer blob plots"

has_module=$(check_module)
if [[ $has_module -gt 0 ]]; then
        echo "No modules available.."
else
  module load R
fi

echo "
Rscript $MERQURY/plot/plot_blob.R -f $count -o $out.hapmers.blob"
Rscript $MERQURY/plot/plot_blob.R -f $count -o $out.hapmers.blob


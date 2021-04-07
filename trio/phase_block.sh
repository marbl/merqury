#!/bin/bash

echo "Usage: ./phase_block.sh <asm.fasta> <hap1.meryl> <hap2.meryl> <out>"

if [[ $# -lt 4 ]]; then
  exit -1
fi

source $MERQURY/util/util.sh

scaff=`link $1`
scaff=${scaff/.fasta/}

hap1=`link $2`
hap2=`link $3`
out=$4

k=`meryl print $hap1 | head -n 2 | tail -n 1 | awk '{print length($1)}'`
echo "Detected k-mer size: $k"

if [[ ! -e $scaff.gaps ]]; then
  echo "
  Get gaps"
  java -jar -Xmx4g $MERQURY/trio/fastaGetGaps.jar $scaff.fasta $scaff.gaps
fi
awk '{print $1"\t"$2"\t"$3"\tgap"}' $scaff.gaps > $scaff.gaps.bed
cat $scaff.gaps.bed > $scaff.bed

echo "
Generate haplotype marker sites bed
"
if [ ! -s $out.sort.bed ]; then
  meryl-lookup -bed -sequence $scaff.fasta -mers $hap1 $hap2 -labels ${hap1/.meryl/} ${hap2/.meryl/} > $out.sort.bed
else
  echo "*** Found $out.sort.bed. Skipping this step. ***"
fi

for hap in $hap1 $hap2
do
  hap=${hap/.meryl}
  echo "
  -- Generating $out.$hap.wig"
  if [ ! -s $out.$hap.wig ]; then
    meryl-lookup -wig-depth -sequence $scaff.fasta -mers $hap.meryl > $out.$hap.wig
  else
    echo "*** Found $out.$hap.wig. Skipping this step. ***"
  fi
done

echo ""

echo "
$MERQURY/trio/switch_error.sh $out.sort.bed $out 100 20000"
$MERQURY/trio/switch_error.sh $out.sort.bed $out 100 20000
echo


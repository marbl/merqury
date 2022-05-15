#!/bin/bash

if [[ "$#" -lt 3 ]]; then
  echo
  echo "Usage: ./false_duplications_track.sh name.asm.spectra-cn.hist asm.fasta reads.meryl"
  echo "Get bed and wig tracks for the additional k-mers found in asm.fasta in the single and two copy k-mer peaks from the reads"
  echo 
  echo "  name.asm.spectra-cn.hist: spectra-cn.hist generated with Merqury for a (pseudo-)haplotype or mixed haplotype assembly"
  echo "  asm.fasta  : assembly fasta used in Merqury. requires asm.meryl in the same path"
  echo "  reads.meryl: reads meryl db used in Merqury"
  echo
  exit 0
fi

hist=$1
asm_fa=$2
reads=$3
asm=`echo $asm_fa | sed 's/.gz$//g' | sed 's/.fasta$//g' | sed 's/.fa$//g'`

cutoff=`cat $hist  | awk '$1==1 {print $2"\t"$3}' | awk -v max=0 'max<$2 {max=$2; mult=$1 } END {printf "%.0f\n", mult*(1.5)}'`
echo "Using cutoff: $cutoff"

meryl intersect [ greater-than 1 $asm.meryl ] [ less-than $cutoff $reads ] output tmp.fd.meryl

meryl-lookup -bed -sequence $2 -mers tmp.fd.meryl |\
  bedtools merge -i - > $asm.fd.bed

meryl-lookup -wig-depth -sequence $2 -mers tmp.fd.meryl > $asm.fd.wig


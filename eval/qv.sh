#!/bin/bash

if [[ "$#" -lt 3 ]]; then
	echo "Usage: ./qv.sh <read.meryl> <asm1.fasta> [asm2.fasta] <out>"
	echo
	echo -e "\t<read.meryl>:\tk-mer db of the (illumina) read set"
	echo -e "\t<asm1.fasta>:\t assembly 1"
	echo -e "\t[asm2.fasta]:\t assembly 2, optional"
	echo -e "\t<out>.qv:\tQV of asm1, asm2 and both (asm1+asm2)"
	echo
	echo "** This script calculates the QV only and exits. **"
	echo "   Run spectra_cn.sh for full copy number analysis."
	exit 0
fi
source $MERQURY/util/util.sh

read_db=`link $1`
asm1_fa=`link $2`
name=$4

k=`meryl print $read_db | head -n 2 | tail -n 1 | awk '{print length($1)}'`
echo "Detected k-mer size $k"

if [[ "$#" -eq 3 ]]; then
	asm2_fa=""
	name=$3
else
	asm2_fa=`link $3`
	echo "Found asm2: $asm2_fa"
fi

asm1=`echo $asm1_fa | sed 's/.fasta.gz//g' | sed 's/.fa.gz//g' | sed 's/.fasta//g' | sed 's/.fa//g'`
for asm_fa in $asm1_fa $asm2_fa
do
	asm=`echo $asm_fa | sed 's/.fasta.gz//g' | sed 's/.fa.gz//g' | sed 's/.fasta//g' | sed 's/.fa//g'`

	if [[ ! -e $asm.meryl ]]; then
		echo "# Generate meryl db for $asm"
		meryl count k=$k output $asm.meryl $asm_fa
		echo
	fi

	meryl difference output $asm.0.meryl $asm.meryl $read_db

  echo "# QV statistics for $asm"
  ASM_ONLY=`meryl statistics $asm.0.meryl  | head -n4 | tail -n1 | awk '{print $2}'`
  TOTAL=`meryl statistics $asm.meryl  | head -n4 | tail -n1 | awk '{print $2}'`
  ERROR=`echo "$ASM_ONLY $TOTAL" | awk -v k=$k '{print (1-(1-$1/$2)^(1/k))}'`
  QV=`echo "$ASM_ONLY $TOTAL" | awk -v k=$k '{print (-10*log(1-(1-$1/$2)^(1/k))/log(10))}'`
  echo -e "$asm\t$ASM_ONLY\t$TOTAL\t$QV\t$ERROR" >> $name.qv
  echo

  meryl-lookup -existence -sequence $asm_fa -mers $asm.0.meryl/ | \
    awk -v k=$k '{print $1"\t"$4"\t"$2"\t"(-10*log(1-(1-$4/$2)^(1/k))/log(10))"\t"(1-(1-$4/$2)^(1/k))}' > $name.$asm.qv
done

if [[ "$asm2_fa" == "" ]]; then
	echo -e "No asm2 found.\nDone!"
  echo "Remove intermediate files:
rm -r $asm1.0.meryl"
	exit 0
fi

asm2=`echo $asm2_fa | sed 's/.fasta.gz//g' | sed 's/.fa.gz//g' | sed 's/.fasta//g' | sed 's/.fa//g'`

asm="both"

meryl union-sum output $asm.meryl   $asm1.meryl   $asm2.meryl
meryl union-sum output $asm.0.meryl $asm1.0.meryl $asm2.0.meryl

echo "# QV statistics for $asm"
ASM_ONLY=`meryl statistics $asm.0.meryl  | head -n4 | tail -n1 | awk '{print $2}'`
TOTAL=`meryl statistics $asm.meryl  | head -n4 | tail -n1 | awk '{print $2}'`
ERROR=`echo "$ASM_ONLY $TOTAL" | awk -v k=$k '{print (1-(1-$1/$2)^(1/k))}'`
QV=`echo "$ASM_ONLY $TOTAL" | awk -v k=$k '{print (-10*log(1-(1-$1/$2)^(1/k))/log(10))}'`
echo -e "$asm\t$ASM_ONLY\t$TOTAL\t$QV\t$ERROR" >> $name.qv
echo

echo "Done!"
echo "Remove intermediate files:
rm -r $asm1.0.meryl $asm2.0.meryl $asm.0.meryl"


#!/bin/bash


echo "Usage: ./hap_blob.sh <hap1.meryl> <hap2.meryl> <asm1.fasta> [asm2.fasta] <out>"

if [[ $# -lt 4 ]]; then
	exit -1
fi

hap1=$1
hap2=$2
asm1=$3
asm2=$4
out=$5

if [[ -z $hap1 || -z $hap2 ]]; then
	echo "Check <hap1.meryl> and <hap2.meryl>."
	exit -1
fi

if [[ -z $asm1 ]]; then
	echo "No .fasta file given. Exit."
	exit -1
fi

if [[ -z $out ]]; then
	echo "No asm2 given."
	echo
	asm2=""
	out=$4
fi

count=$out.hapmers.count
echo -e "Assembly\tContig\t${hap1/.meryl}\t${hap2/.meryl}\tSize" > $count
for asm in $asm1 $asm2
do
	name=`echo $asm | sed 's/.fasta$//g' | sed 's/.fa$//g' | sed 's/.fasta.gz$//g' | sed 's/.fa.gz$//g'`
	echo "
	Start processing $name"

	for hap in $hap1 $hap2
	do
		hap_name=${hap/.meryl}
		if [ -s $name.$hap_name.count ]; then
			echo "Found $name.$hap_name.count"
		else
			echo -e "\n\n--- Count k-mers in $hap_name ---
			meryl-lookup -existence -sequence $asm -mers $hap > $name.$hap_name.count"
			meryl-lookup -existence -sequence $asm -mers $hap > $name.$hap_name.count
		fi
	done

	awk -v asm=$name '{print asm"\t"$1"\t"$NF}' $name.${hap1/.meryl/}.count > $asm.tmp
	awk '{print $NF"\t"$(NF-2)}' $name.${hap2/.meryl/}.count | paste $asm.tmp - >> $count
	rm $asm.tmp
done

echo "
Plot hap-mer blob plots"

module load R

echo "
Rscript $MERQURY/plot/plot_blob.R -f $count -o $out.hapmers.blob"
Rscript $MERQURY/plot/plot_blob.R -f $count -o $out.hapmers.blob


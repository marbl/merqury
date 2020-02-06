#!/bin/bash

echo "Usage: ./phase_block.sh <asm.fasta> <hap1.meryl> <hap2.meryl> <out>"

if [[ $# -lt 4 ]]; then
	exit -1
fi

scaff=$1
scaff=${scaff/.fasta/}

hap1=$2
hap2=$3
out=$4

module load bedtools
module load samtools

k=`meryl print $hap1 | head -n 2 | tail -n 1 | awk '{print length($1)}'`
echo "Detected k-mer size: $k"

if [ ! -e $scaff.gaps ]; then
	echo "
	Get gaps"
	java -jar -Xmx4g $MERQURY/trio/fastaGetGaps.jar $scaff.fasta $scaff.gaps
fi
awk '{print $1"\t"$2"\t"$3"\tgap"}' $scaff.gaps > $scaff.gaps.bed
cat $scaff.gaps.bed > $scaff.bed

# .fai for generating .tdf files
if [ ! -e $scaff.fasta.fai ]; then
	samtools faidx $scaff.fasta
fi

if [ ! -s $out.sort.bed ]; then
	echo "
	Generate haplotype marker sites bed"
	for hap in $hap1 $hap2
	do
		hap=${hap/.meryl/}
		echo "
		-- $hap"
		hap_short=${hap%.*}
		if [ ! -s $out.$hap.bed ]; then
			meryl-lookup -dump -memory 4 -sequence $scaff.fasta -mers $hap.meryl | awk -v hap=$hap_short -v k=$k '$(NF-4)=="T" {print $1"\t"$(NF-5)"\t"($(NF-5)+k)"\t"hap}' > $out.$hap.bed
		fi
		cat $out.$hap.bed >> $out.bed

		if [ ! -s $out.$hap.tdf ]; then
			igvtools count $out.$hap.bed $out.$hap.tdf $scaff.fasta.fai
		fi
	done

	echo "
	Sort $out.bed"
	bedtools sort -i $out.bed > $out.sort.bed
fi

#$MERQURY/plot/plot_block.sh <in.sort.bed> <out> <num_switch> <short_range> [include_gaps] 
echo "
$MERQURY/trio/switch_error.sh $out.sort.bed $out 10 20000 T"
$MERQURY/trio/switch_error.sh $out.sort.bed $out 10 20000 T
echo



#!/bin/bash

if [[ -z $1 ]]; then
    echo "Usage: ./hapmers_to_bigWig.sh <in.hap.bed> <asm.fai> [convert_pipes]"
    echo -e "\t<in.hap.bed>: ex. out.asm.mat.inherited.bed"
    echo -e "\t<asm.fai>: generate with samtools faidx"
    echo -e "\t[convert_pipes]: convert '|' to '_' in asm seq names by default. Set to F if not wanted."
    exit 0
fi

bed=$1
fai=$2
convert=$3

module load bedtools
module load ucsc/396

bg=${bed/.bed/.bg}

if [[ "$convert" = "F" ]]; then
    echo "# keep pipes"
    sizes=${fai/.fai/.sizes}
    cat $fai | cut -f1-2 > $sizes
    cat $bed | bedtools genomecov -bg -g $sizes -i - > $bg
else
    sizes=${fai/.fai/.sizes}
    cat $fai | cut -f1-2 | sed 's/|/_/g' > $sizes
    cat $bed | sed 's/|/_/g' | bedtools genomecov -bg -g $sizes -i - > $bg
fi

sort=${bg/.bg/.srt.bg}
bedSort $bg $sort

bw=${bed/.bed/.bigwig}
bedGraphToBigWig $sort $sizes $bw

rm $bg $sort


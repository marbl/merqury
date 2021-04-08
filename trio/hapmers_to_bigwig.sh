#!/bin/bash

if [[ -z $1 ]]; then
    echo "Usage: ./hapmers_to_bigWig.sh <in.hap.wig> <asm.fai>"
    echo -e "\t<in.hap.bed>: ex. out.asm.mat.hapmer.wig"
    echo -e "\t<asm.fai>: generate with samtools faidx"
    exit 0
fi

wig=$1
fai=$2

module load ucsc

bw=${wig/.wig/.bw}
wigToBigWig $wig $fai $bw



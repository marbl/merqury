#!/bin/bash

if [[ "$#" -lt 5 ]]; then
  echo "Usage:   \$MERQURY/trio/assign_reads.sh read.gz hap1 hap2 hap1.hapmer.meryl hap2.hapmer.meryl"
  echo "Example: \$MERQURY/trio/assign_reads.sh read1.fastq.gz mat pat mat.hapmer.meryl pat.hapmer.meryl"
  echo "Output:  read_id <tab> num_kmers <tab> num_hap1 <tab> num_hap1_found <tab> num_hap2 <tab> num_hap2_found <tab> assignment"
  echo
  echo "Assignment will be [hap1] [hap2] or [unk], similarly as in trio-binning."
  echo
  exit -1
fi

set -x
set -o pipefail

# Only one input supported for `-sequence`

fq=$1
hap1=$2    #  "mat"
hap2=$3    #  "pat"
hapmer1=$4 #  "mat.hapmer.meryl"
hapmer2=$5 #  "pat.hapmer.meryl"
out=`basename $fq`.assigned

meryl-lookup -existence -sequence $fq -mers $hapmer1 $hapmer2 |\
  awk -v hap1=$hap1 -v hap2=$hap2 '{sco1=$4/$3; sco2=$6/$5; hap=hap1;\
        if(sco2>sco1) {tmp=sco1; sco1=sco2; sco2=tmp; hap=hap2;};    \
        if((sco2==0 && sco1>0) || (sco2>0 && (sco1/sco2>1.0))) { print $0"\t"hap } \
        else {print $0"\tunk"}  }' > $out


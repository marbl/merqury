#!/bin/bash

if [[ "$#" -lt 2 ]]; then
  echo "Usage: ./hamming_error.sh *.hapmers.count asm1.fasta [asm2.fasta]"
  echo "  *.hapmer.count  output from \$MERQURY/trio/hap_blob.sh"
  exit -1
fi

COUNT=$1
ASM1=`echo $2 | sed 's/\.fasta$//g' | sed 's/\.fa$//g' |sed 's/\.fasta\.gz$//g' | sed 's/\.fa\.gz$//g'`

if ! [[ -z $3 ]]; then
  ASM2=`echo $3 | sed 's/\.fasta$//g' | sed 's/\.fa$//g' |sed 's/\.fasta\.gz$//g' | sed 's/\.fa\.gz$//g'`
fi

if ! [[ -s $COUNT ]]; then
  echo "$COUNT does not exist."
  exit -1
fi

cat $COUNT | \
awk '{hap1=$3; hap2=$4; \
  if (NR==1) { hap1_name=$3; hap2_name=$4; print $0"\tHaplotype\tHammingError\t%"} \
  else { \
    tot += hap1 + hap2; \
    if (hap1 > hap2)      { err = hap2; hap = hap1_name; ham = hap2 / (hap1 + hap2) } \
    else if (hap1 < hap2) { err = hap1; hap = hap2_name; ham = hap1 / (hap1 + hap2) } \
    else if (hap1 == hap2 && hap1 > 0) { err = hap1; hap = "Unknown"; ham = hap1 / (hap1 + hap2) } \
    if (hap1 + hap2 == 0) { print $0"\tUnknown\t0\tNA"    }       \
    else                  { print $0"\t"hap"\t"err"\t"100*ham}  } }' \
  > $COUNT.ham

echo -e "Assembly\tHap1\tHap2\tHap1Error(%)\tHap2Error(%)\tMajorHapError(%)" > phase_hammingerror.stats

if [[ -z $3 ]]; then
  cat $COUNT.ham | \
    awk -v asm1=$ASM1 '{
      hap1 = $3; hap2 = $4; err = $7; \
      if ($1==asm1) { asm1_hap1 += hap1; asm1_hap2 += hap2; asm1_err += err; asm1_tot += hap1 + hap2 } \
      } \
      END {print asm1"\t"asm1_hap1"\t"asm1_hap2"\t"100*asm1_hap2/asm1_tot"\t"100*asm1_hap1/asm1_tot"\t"100*asm1_err/asm1_tot } \
    ' >> phase_hammingerror.stats
else
  cat $COUNT.ham | \
    awk -v asm1=$ASM1 -v asm2=$ASM2 '{
      hap1 = $3; hap2 = $4; err = $7; \
      if      ($1==asm1) { asm1_hap1 += hap1; asm1_hap2 += hap2; asm1_err += err; asm1_tot += hap1 + hap2 } \
      else if ($1==asm2) { asm2_hap1 += hap1; asm2_hap2 += hap2; asm2_err += err; asm2_tot += hap1 + hap2 } \
      } \
      END {print asm1"\t"asm1_hap1"\t"asm1_hap2"\t"100*asm1_hap2/asm1_tot"\t"100*asm1_hap1/asm1_tot"\t"100*asm1_err/asm1_tot"\n" \
                 asm2"\t"asm2_hap1"\t"asm2_hap2"\t"100*asm2_hap2/asm2_tot"\t"100*asm2_hap1/asm2_tot"\t"100*asm2_err/asm2_tot } \
    ' >> phase_hammingerror.stats
fi

cat phase_hammingerror.stats

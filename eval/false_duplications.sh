#!/bin/bash

if [[ -z $1 ]]; then
	echo "Usage: ./false_duplications.sh <name.asm.spectra-cn.hist>"
	echo "Get the number of additional k-mers found in an assembly in the single and two copy k-mer peaks from the reads"
	echo -e "<name.asm.spectra-cn.hist>: spectra-cn.hist generated with Merqury for a pseudo-haplotype or mixed haplotype assembly"
	exit 0
fi

hist=$1

cutoff=`cat $hist  | awk '$1==1 {print $2"\t"$3}' | awk -v max=0 'max<$2 {max=$2; mult=$1 } END {printf "%.0f\n", mult*(1.5)}'`
one_cp=`awk -v cutoff=$cutoff '$1==1 && $2<cutoff {sum+=$NF} END {print sum}' $hist`
two_cp=`awk -v cutoff=$cutoff '$1==2 && $2<cutoff {sum+=$NF} END {print sum}' $hist`
thr_cp=`awk -v cutoff=$cutoff '$1==3 && $2<cutoff {sum+=$NF} END {print sum}' $hist`
fou_cp=`awk -v cutoff=$cutoff '$1==4 && $2<cutoff {sum+=$NF} END {print sum}' $hist`
mor_cp=`awk -v cutoff=$cutoff '$1==">4" && $2<cutoff {sum+=$NF} END {print sum}' $hist`
DUPS_TOTAL=`echo "$one_cp $two_cp $thr_cp $fou_cp $mor_cp" | awk '{dup=$2+$3+$4+$5; all=dup+$1} END {print $1"\t"$2"\t"$3"\t"$4"\t"$5"\t"dup"\t"all"\t"(100*dup/all)}'`
echo -e "hist\tcutoff\t1\t2\t3\t4\t>4\tdup(>1)\tall\tdup%"
echo -e "$hist\t$cutoff\t$DUPS_TOTAL"


#!/bin/bash

if [[ $# -lt 4 ]]; then
	echo "Usage: ./switch_error.sh <in.sort.bed> <out> <num_switch> <short_range> [include_gaps]"
	echo "	<in.sort.bed>:	generated with trio/phase_block.sh"
	echo "	<out>:		output prefix; automatically appends given <num_switch> and <short_range>"
	echo "	<num_switch>:	number of switches allowed in <short_range>"
	echo "	<short_range>:	interval to be determined as short-range switch (bp)"
	echo "	[include_gaps]:	F for excluding gaps. Set for restricting to in-contig blocks [DEFAUTL=T]"
	echo "Arang Rhie, 2020-02-13. arrhie@gmail.com"
	exit -1
fi

bed=$1
out=$2
num_switch=$3
short_range=$4
include_gaps=$5

out=$out.${num_switch}_$short_range

if [ -s $out.phased_block.bed 2> /dev/null ]; then
	echo "*** Found $out.phased_block.bed ***"
else
	echo "
	java -jar -Xmx1g $MERQURY/trio/bedMerToPhaseBlock.jar $bed $out $num_switch $short_range $include_gaps"
	java -jar -Xmx1g $MERQURY/trio/bedMerToPhaseBlock.jar $bed $out $num_switch $short_range $include_gaps
fi
echo

SWITCH_ERR=`awk -v swi=0 -v tot=0 '{swi+=$(NF-1); tot+=$NF} END { print swi"\t"tot"\t"((100.0*swi)/tot)"%" }' $out.phased_block.bed`
echo "$out switch error rate (%) (Num. switches / Total markers found): $SWITCH_ERR" > $out.switches.txt


echo "
java -jar -Xmx1g $MERQURY/eval/bedCalcN50.jar $out.phased_block.bed | tail -n1 | awk -v out=$out -v swi=\"$SWITCH_ERR\" '{print out\"\t\"\$0\"\tswi}' - >> $out.phased_block.stats"
java -jar -Xmx1g $MERQURY/eval/bedCalcN50.jar $out.phased_block.bed | tail -n1 | awk -v out=$out -v swi="$SWITCH_ERR" '{print out"\t"$0"\t"swi}' - >> $out.phased_block.stats
echo

count=$out.phased_block.counts

# Get haplotypes
haplotypes=`cut -f4 $out.phased_block.bed | sort -u | grep -v gap | tr '\n' ' '`
hap1=`echo $haplotypes | awk '{print $1}'`
hap2=`echo $haplotypes | awk '{print $2}'`

echo "Count $hap1 and $hap2 hap-mers per block to $count"
echo -e "Block\tRange\t$hap1\t$hap2\tSize" > $count
awk -v hap1=$hap1 -v hap2=$hap2 '{ swi=$(NF-1); phase=$NF; {if ($4==hap1) { hap1_cnt=phase; hap2_cnt=swi; } else if ($4==hap2) { hap1_cnt=swi; hap2_cnt=phase; }} {print $4"\t"$1"_"$2"_"$3"\t"hap1_cnt"\t"hap2_cnt"\t"($3-$2)}}' $out.phased_block.bed >> $count

source $MERQURY/util/util.sh

has_module=$(check_module)
if [[ $has_module -gt 0 ]]; then
        echo "No modules available.."
else
	module load R
fi

echo "
Rscript $MERQURY/plot/plot_blob.R -f $count -o $out.phased_block.blob"
Rscript $MERQURY/plot/plot_blob.R -f $count -o $out.phased_block.blob



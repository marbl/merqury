#!/usr/bin/env bash


if [[ "$#" -lt 3 ]]; then
    echo "Usage: ./block_n_stats.sh <asm1.fasta> <out.asm1.*.phased_block.bed> [<asm2.fasta> <out.asm2.*.phased_block.bed>] <out> [genome_size]"
    echo
    echo -e "\t<asm1.fasta>:\tAssembly 1 fasta file"
    echo -e "\t<*.asm1.*.phased_block.bed>:\tAssembly 1 phased block .bed file"
    echo
    echo -e "\t<asm2.fasta>:\tAssembly 2 fasta file (optional)"
    echo -e "\t<*.asm2.*.phased_block.bed>:\tAssembly 1 phased block .bed file (required when <asm2.fasta> is provided)"
    echo
    echo -e "\t<out>:\tOutput prefix"
    echo -e "\t[genome_size]:\tEstimated genome size (bp)"
    exit -1
fi

asm1=$1
asm1_name=`echo $asm1 | sed 's/\.fasta$//g' | sed 's/\.fa$//g'`
block1=$2

asm2=""
if [[ "$#" -gt 4 ]]; then
  asm2=$3
  asm2_name=`echo $asm2 | sed 's/\.fasta$//g' | sed 's/\.fa$//g'`
  block2=$4
  out=$5
  g_size=$6
else
  out=$3
  g_size=$4
fi

source $MERQURY/util/util.sh

has_module=$(check_module)
if [[ $has_module -gt 0 ]]; then
        echo "No modules available.."
else
	module load bedtools
	module load samtools
	module load R
fi

for asm in $asm1 $asm2
do
    if [[ ! -e $asm.fai ]]; then
        echo "# Generate $asm.fai"
        samtools faidx $asm
    else
        echo "*** # Found $asm.fai ***"
    fi
    echo

    asm_name=`echo $asm | sed 's/\.fasta$//g' | sed 's/\.fa$//g'`
    if [[ ! -e $asm_name.gaps.bed ]]; then
        echo "# Get gaps"
        java -jar -Xmx4g $MERQURY/trio/fastaGetGaps.jar $asm $asm_name.gaps
        awk -F "\t" '{print $1"\t"$2"\t"$3"\tgap"}' $asm_name.gaps > $asm_name.gaps.bed
    else
        echo "*** # Found $asm_name.gaps.bed ***"
    fi
    echo
    
    num_gaps=`wc -l $asm_name.gaps.bed | awk '{print $1}'`
    if [[ $num_gaps -gt 0 ]]; then
        echo "# Found $num_gaps. Generating stats for both scaffolds and contigs."
        awk -v asm=$asm_name '{print "scaffold\t"asm"\t"$2}' $asm.fai | sort -nr -k3 - > $out.$asm_name.scaff.sizes
        awk '{print $1"\t0\t"$2}' $asm.fai | bedtools subtract -a - -b $asm_name.gaps.bed | awk -v asm=$asm_name '{print "contig\t"asm"\t"($NF-$(NF-1))}' | sort -nr -k3 - > $out.$asm_name.contig.sizes
    else
        echo "# No gaps found. This is a contig set."
        awk -v asm=$asm_name '{print "contig\t"asm"\t"$2}'   $asm.fai | sort -nr -k3 - > $out.$asm_name.contig.sizes
    fi
    echo
done

block1=`ls $block1`
echo "# Convert $block1 to sizes"
awk -v asm="block" -F "\t" '{print asm"\t"$4"\t"($3-$2)}' $block1 | sort -nr -k3 - > ${block1/.bed/.sizes}
echo " Result saved as ${block1/.bed/.sizes}"
echo

if [[ -s $out.$asm1_name.scaff.sizes ]]; then
    scaff="-s $out.$asm1_name.scaff.sizes"
fi

if [[ "$g_size" != "" ]]; then
    g_size="-g $g_size"
fi

echo "# Plot $block1"
echo "\
Rscript $MERQURY/plot/plot_block_N.R -b ${block1/.bed/.sizes} -c $out.$asm1_name.contig.sizes $scaff -o $out.$asm1_name $g_size"
Rscript $MERQURY/plot/plot_block_N.R -b ${block1/.bed/.sizes} -c $out.$asm1_name.contig.sizes $scaff -o $out.$asm1_name $g_size
echo

if [[ "$block2" == "" ]]; then
    echo "# No block2 found. Done!"
    exit 0
fi

block2=`ls $block2`
echo "# Convert $block2 to sizes"
awk -v asm="block" -F "\t" '{print asm"\t"$4"\t"($3-$2)}' $block2 | sort -nr -k3 > ${block2/.bed/.sizes}
echo " Result saved as ${block2/.bed/.sizes}"
echo

if [[ -s $out.$asm2_name.scaff.sizes ]]; then
    scaff="-s $out.$asm2_name.scaff.sizes"
fi

echo "# Plot $block2"
echo "\
Rscript $MERQURY/plot/plot_block_N.R -b ${block2/.bed/.sizes} -c $out.$asm2_name.contig.sizes $scaff -o $out.$asm2_name $g_size"
Rscript $MERQURY/plot/plot_block_N.R -b ${block2/.bed/.sizes} -c $out.$asm2_name.contig.sizes $scaff -o $out.$asm2_name $g_size
echo


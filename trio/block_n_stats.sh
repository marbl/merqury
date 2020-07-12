#!/bin/bash


if [[ "$#" -lt 3 ]]; then
    echo "Usage: ./block_n_stats.sh <asm1.fasta> <asm1.*.phased_block.bed> [<asm2.fasta> <asm2.*.phased_block.bed>] <out> [genome_size]"
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
asm1=${asm1/.fasta/}
block1=$2

asm2=""
if [[ "$#" -gt 4 ]]; then
    asm2=$3
    asm2=${asm2/.fasta/}
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
    if [[ ! -e $asm.fasta.fai ]]; then
        echo "# Generate $asm.fasta.fai"
        samtools faidx $asm.fasta
    else
        echo "*** # Found $asm.fasta.fai ***"
    fi
    echo

    if [[ ! -e $asm.gaps.bed ]]; then
        echo "# Get gaps"
        java -jar -Xmx4g $MERQURY/trio/fastaGetGaps.jar $asm.fasta $asm.gaps
        awk -F "\t" '{print $1"\t"$2"\t"$3"\tgap"}' $asm.gaps > $asm.gaps.bed
    else
        echo "*** # Found $asm.gaps.bed ***"
    fi
    echo
    
    num_gaps=`wc -l $asm.gaps.bed | awk '{print $1}'`
    if [[ $num_gaps -gt 0 ]]; then
        echo "# Found $num_gaps. Generating stats for both scaffolds and contigs."
        awk -v asm=$asm '{print "scaffold\t"asm"\t"$2}' $asm.fasta.fai | sort -nr -k3 - > $out.$asm.scaff.sizes
        awk '{print $1"\t0\t"$2}' $asm.fasta.fai | bedtools subtract -a - -b $asm.gaps.bed | awk -v asm=$asm '{print "contig\t"asm"\t"($NF-$(NF-1))}' | sort -nr -k3 - > $out.$asm.contig.sizes
    else
        echo "# No gaps found. This is a contig set."
        awk -v asm=$asm '{print "contig\t"asm"\t"$2}' $asm.fasta.fai | sort -nr -k3 - > $out.$asm.contig.sizes
    fi
    echo
done

block1=`ls $block1`
echo "# Convert $block1 to sizes"
awk -v asm="block" -F "\t" '{print asm"\t"$4"\t"($3-$2)}' $block1 | sort -nr -k3 - > ${block1/.bed/.sizes}
echo " Result saved as ${block1/.bed/.sizes}"
echo

if [[ -s $out.$asm1.scaff.sizes ]]; then
    scaff="-s $out.$asm1.scaff.sizes"
fi

if [[ "$g_size" != "" ]]; then
    g_size="-g $g_size"
fi

echo "# Plot $block1"
echo "\
Rscript $MERQURY/plot/plot_block_N.R -b ${block1/.bed/.sizes} -c $out.$asm1.contig.sizes $scaff -o $out.$asm1 $g_size"
Rscript $MERQURY/plot/plot_block_N.R -b ${block1/.bed/.sizes} -c $out.$asm1.contig.sizes $scaff -o $out.$asm1 $g_size
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

if [[ -s $out.$asm2.scaff.sizes ]]; then
    scaff="-s $out.$asm2.scaff.sizes"
fi

echo "# Plot $block2"
echo "\
Rscript $MERQURY/plot/plot_block_N.R -b ${block2/.bed/.sizes} -c $out.$asm2.contig.sizes $scaff -o $out.$asm2 $g_size"
Rscript $MERQURY/plot/plot_block_N.R -b ${block2/.bed/.sizes} -c $out.$asm2.contig.sizes $scaff -o $out.$asm2 $g_size
echo


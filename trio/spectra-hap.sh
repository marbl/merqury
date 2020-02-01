#!/bin/bash

echo "Usage: ./spectra-hap.sh <reads.meryl> <hap1.meryl> <hap2.meryl> <k> <asm1.fasta> [asm2.fasta] <out-prefix>"
echo

if [[ $# -lt 6 ]]; then
	echo "Not enough arguements given."
	exit -1
fi

read=$1
read_hap1=$2 # .meryl    Haplotype1 specific kmers with counts from reads
read_hap2=$3 # .meryl    Haplotype2 specific kmers with counts from reads
k=$4    # kmer
asm1_fa=$5 # .fasta    Haplotype1 assembly
asm2_fa=$6 # .fasta    Haplotype2 assembly
name=$7    # output prefix
if [ -z $name ]; then
	name=$6
	asm2_fa=""
fi

if [ -z $read_hap1 ]; then
	echo "No input provided. Exit."
	exit -1
fi

## Remove this line if R is properly installed ##
echo "Load R"
module load R                                   #
#################################################

read=${read/.meryl/}		  # all read counts
read_hap1=${read_hap1/.meryl/}    # pat specific mers with read counts
read_hap2=${read_hap2/.meryl/}    # mat specific mers with read counts

hap_hist=$name.hapmers.hist
cn_hist="spectra-hap-cn.hist"

echo "
=== Get histogram from all and inherited hap-mers ==="
echo
if [ -s $hap_hist ]; then
	echo "*** $hap_hist found. Skip re-counting. ***"
	echo
else
	echo -e "Assembly\tkmer_multiplicity\tCount" > $hap_hist
	meryl histogram $read.meryl | awk -v asm="read-total" '{print asm"\t"$0}' >> $hap_hist

	for hap in $read_hap1 $read_hap2
	do
	    meryl histogram $hap.meryl | awk -v asm="${hap}" '{print asm"\t"$0}' >> $hap_hist
	done
fi

echo "# Plot $hap_hist"
$MERQURY/plot/plot_spectra_asm.R -f $hap_hist -o ${hap_hist/.hist/}
echo

for asm_fa in $asm1_fa $asm2_fa
do
    asm=`echo $asm_fa | sed 's/.fasta$//g' | sed 's/.fa$//g' | sed 's/.fasta.gz$//g' | sed 's/.fa.gz$//g'`
    if ! [[ "$(ls -A $asm.meryl 2> /dev/null )" ]]; then
        echo "Generate meryl db for $asm_fa"
        meryl count k=$k output $asm.meryl $asm_fa
    fi
    
    # For each haplotype
    for read_hap in $read_hap1 $read_hap2
    do
	read_hap=${read_hap/.meryl/}
	
	echo "=== Start processing $read_hap from $asm ==="
	echo
	echo "# Hap-mer completeness for $read_hap in $asm"
	meryl intersect output $read_hap.$asm.meryl $read_hap.meryl $asm.meryl
	TOTAL=`meryl statistics $read_hap.meryl | head -n3 | tail -n1 | awk '{print $2}'`
	ASM=`meryl statistics $read_hap.$asm.meryl | head -n3 | tail -n1 | awk '{print $2}'`
	echo -e "${asm}\t${read_hap}\t${ASM}\t${TOTAL}" | awk '{print $0"\t"((100*$3)/$4)}' >> completeness.stats
	echo

        if [ -s $name.$asm.$read_hap.$cn_hist ]; then
                echo
                echo "*** $name.$asm.$read_hap.$cn_hist found. Skip re-counting. ***"
                echo
        else
		echo "=== Copy-number histogram per haplotype specific k-mers ==="
		echo

		echo -e "Copies\tkmer_multiplicity\tCount" > $name.$asm.$read_hap.$cn_hist

		echo "Read-only .."
		meryl difference output read.$read_hap.0.meryl $read_hap.meryl $asm.meryl
		meryl histogram read.$read_hap.0.meryl | awk -v read=$read_hap '{print read"-only\t"$0}' >> $name.$asm.$read_hap.$cn_hist
		rm -r read.$read_hap.0.meryl
		echo

		for i in $(seq 1 4)
		do
		    echo "Copy = $i .."
		    meryl intersect output read.$read_hap.$i.meryl $read_hap.$asm.meryl [ equal-to $i ${asm}.meryl ]
		    meryl histogram read.$read_hap.$i.meryl | awk -v cn=$i '{print cn"\t"$0}' >> $name.$asm.$read_hap.$cn_hist
		    rm -r read.$read_hap.$i.meryl
		    echo
		done

		echo "Copy >4 .."
		meryl intersect output read.$read_hap.gt$i.meryl $read_hap.$asm.meryl [ greater-than $i ${asm}.meryl ]
		meryl histogram read.$read_hap.gt$i.meryl | awk -v cn=">$i" '{print cn"\t"$0}' >> $name.$asm.$read_hap.$cn_hist
		rm -r read.$read_hap.gt$i.meryl
		rm -r $read_hap.$asm.meryl
		echo
	fi

	echo "# Plot $name.$asm.$read_hap.$cn_hist"
        $MERQURY/plot/plot_spectra_cn.R -f $name.$asm.$read_hap.$cn_hist -o $name.$asm.$read_hap
	echo
    done
done

if [[ "$asm2_fa" = "" ]]; then
    echo "No asm2_fa provided."
    echo "Bye!"
    exit 0
fi

echo "# Combined hap-mer completeness"
asm1=`echo $asm1_fa | sed 's/.fasta$//g' | sed 's/.fa$//g' | sed 's/.fasta.gz$//g' | sed 's/.fa.gz$//g'`
asm2=`echo $asm2_fa | sed 's/.fasta$//g' | sed 's/.fa$//g' | sed 's/.fasta.gz$//g' | sed 's/.fa.gz$//g'`
meryl union-sum output both.meryl $asm1.meryl $asm2.meryl
for read_hap in $read_hap1 $read_hap2
do
	meryl intersect output $read_hap.both.meryl both.meryl $read_hap.meryl
        TOTAL=`meryl statistics $read_hap.meryl | head -n3 | tail -n1 | awk '{print $2}'`
        ASM=`meryl statistics $read_hap.both.meryl | head -n3 | tail -n1 | awk '{print $2}'`
        echo -e "both\t${read_hap}\t${ASM}\t${TOTAL}" | awk '{print $0"\t"((100*$3)/$4)}' >> completeness.stats
	rm -r $read_hap.both.meryl
done
rm -r both.meryl
echo

echo "Bye!"


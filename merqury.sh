#! /bin/bash

if [[ "$#" -lt 3 ]]; then
	echo "Usage: merqury.sh <read-db.meryl> [<mat.meryl> <pat.meryl>] <asm1.fasta> [asm2.fasta] <out>"
	echo -e "\t<read-db.meryl>\t: k-mer counts of the read set"
	echo -e "\t<mat.meryl>\t\t: k-mer counts of the maternal haplotype (ex. mat.inherited.meryl)"
	echo -e "\t<pat.meryl>\t\t: k-mer counts of the paternal haplotype (ex. pat.inherited.meryl)"
	echo -e "\t<asm1.fasta>\t: Assembly fasta file (ex. pri.fasta, hap1.fasta or maternal.fasta)"
	echo -e "\t[asm2.fasta]\t: Additional fasta file (ex. alt.fasta, hap2.fasta or paternal.fasta)"
	echo -e "\t*asm1.meryl and asm2.meryl will be generated. Avoid using the same names as the hap-mer dbs"
	echo -e "\t<out>\t\t: Output prefix"
	echo -e "Arang Rhie, 2020-01-29. arrhie@gmail.com"
	exit 0
fi

readdb=$1

if [[ "$#" -gt 4 ]]; then
	echo "Haplotype dbs provided."
	echo "Running Merqury in trio mode..."
	hap1=$2
	hap2=$3
	asm1=$4
	if [[ "$#" -eq 5 ]]; then
		out=$5
	else
		asm2=$5
		out=$6
	fi
elif [[ "$#" -gt 2 ]]; then
	echo "No haplotype dbs provided."
	echo "Running Merqury in non-trio mode..."
	asm1=$3
	if [[ "$#" -eq 3 ]]; then
		out=$3
	else
		asm2=$3
		out=$4
	fi
fi

if [ -e $out ]; then
        echo "$out already exists. Provide a different name. (Are we missing the <out>?)"
        exit -1
fi

mkdir -p logs

echo "
Get spectra-cn plots and QV stats"
name=$out.spectra-cn
log=logs/$name.log
sh $MERQURY/eval/spectra-cn.sh $readdb $asm1 $asm2 $out > $log 2> $log

if [ -z $hap1 ]; then
	exit 0
fi

echo "
Get blob plots"
name=$out.blob
log=logs/$name.log
sh $MERQURY/trio/hap_blob.sh $hap1 $hap2 $asm1 $asm2 $out > $log 2> $log

echo "
Get haplotype specfic spectra-cn plots"
name=$out.spectra-hap
log=logs/$name.log
sh $MERQURY/trio/spectra-hap.sh $readdb $hap1 $hap2 $asm1 $asm2 $out > $log 2> $log

echo "
Get phase blocks"
name=$out.phase-block1
log=logs/$name.log

sh $MERQURY/trio/phase_block.sh $asm1 $hap1 $hap2 $out.${asm1/.fasta/}  > $log 2> $log
echo

if [ -z $asm2 ] ; then
	exit 0
fi

name=$out.phase-block2
log=logs/$name.log
sh $MERQURY/trio/phase_block.sh $asm2 $hap1 $hap2 $out.${asm2/.fasta/}  > $log 2> $log



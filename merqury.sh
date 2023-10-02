#!/usr/bin/env bash

if [[ "$#" -lt 3 ]]; then
  echo "Usage: merqury.sh [-c] <read-db.meryl> [<mat.meryl> <pat.meryl>] <asm1.fasta> [asm2.fasta] <out>"
  echo -e "\t-c\t\t: [OPTIONAL] input meryl databases are homopolymer compressed, while asm.fasta isn't"
  echo -e "\t\t\t  This option is not supported for trio-based analysis. Use pre-compressed assemblies with no -c option." 
  echo -e "\t<read-db.meryl>\t: k-mer counts of the read set"
  echo -e "\t<mat.meryl>\t: k-mer counts of the maternal haplotype (ex. mat.hapmer.meryl)"
  echo -e "\t<pat.meryl>\t: k-mer counts of the paternal haplotype (ex. pat.hapmer.meryl)"
  echo -e "\t<asm1.fasta>\t: Assembly fasta file (ex. pri.fasta, hap1.fasta or maternal.fasta)"
  echo -e "\t[asm2.fasta]\t: Additional fasta file (ex. alt.fasta, hap2.fasta or paternal.fasta)"
  echo -e "\t*asm1.meryl and asm2.meryl will be generated. Avoid using the same names as the hap-mer dbs"
  echo -e "\t<out>\t\t: Output prefix"
  echo -e "Arang Rhie, 2022-09-07. arrhie@gmail.com"
  exit 0
fi

source $MERQURY/util/util.sh

compress=""
if [ "x$1" = "x-c" ]; then
  compress="-c"
  shift
fi

readdb=`link $1`
echo "read: $readdb"
echo

if [[ "$#" -gt 4 ]]; then
	echo "Haplotype dbs provided."
	echo "Running Merqury in trio mode..."
	echo

	hap1=`link $2`
	hap2=`link $3`
	asm1=`link $4`
	echo "hap1: $hap1"
	echo "hap2: $hap2"
	echo "asm1: $asm1"
	if [[ "$#" -eq 5 ]]; then
		out=$5
	else
		asm2=`link $5`
		out=$6
		echo "asm2: $asm2"
	fi

elif [[ "$#" -gt 2 ]]; then
	echo "No haplotype dbs provided."
	echo "Running Merqury in non-trio mode..."
	echo

	asm1=`link $2`
	echo "asm1: $asm1"
	if [[ "$#" -eq 3 ]]; then
		out=$3
	else
		asm2=`link $3`
		out=$4
		echo "asm2: $asm2"
	fi
fi

echo "out : $out"
echo

if [ -e $out ]; then
        echo "$out already exists. Provide a different name. (Are we missing the <out>?)"
        exit -1
fi

mkdir -p logs

echo "
Get spectra-cn plots and QV stats"
name=$out.spectra-cn
log=logs/$name.log
$MERQURY/eval/spectra-cn.sh $compress $readdb $asm1 $asm2 $out &> $log

if [ -z $hap1 ]; then
	exit 0
fi

if [ ! -z $compress ]; then
	echo "[ WARNING ] :: -c option is not supported for trio-based analysis."
	echo "[ WARNING ] :: Use pre-compressed assemblies with no -c option."
	exit 0
fi

echo "
Get blob plots"
name=$out.blob
log=logs/$name.log
$MERQURY/trio/hap_blob.sh $hap1 $hap2 $asm1 $asm2 $out &> $log

echo "
Get haplotype specfic spectra-cn plots"
name=$out.spectra-hap
log=logs/$name.log
$MERQURY/trio/spectra-hap.sh $readdb $hap1 $hap2 $asm1 $asm2 $out &> $log

echo "
Get phase blocks"
name=$out.phase-block1
log=logs/$name.log

asm1_name=`echo $asm1 | sed 's/.fasta$//g' | sed 's/.fa$//g'`
$MERQURY/trio/phase_block.sh $asm1 $hap1 $hap2 $out.$asm1_name &> $log
echo

if [ -z $asm2 ] ; then
	echo "Get block N plots"
	name=$out.block_N
	log=logs/$name.log

	$MERQURY/trio/block_n_stats.sh $asm1 $out.$asm1_name.*.phased_block.bed $out

	exit 0
fi

name=$out.phase-block2
log=logs/$name.log

asm2_name=`echo $asm2 | sed 's/.fasta$//g' | sed 's/.fa$//g'`
$MERQURY/trio/phase_block.sh $asm2 $hap1 $hap2 $out.$asm2_name &> $log

echo "
Get block N plots"
name=$out.block_N
log=logs/$name.log

$MERQURY/trio/block_n_stats.sh $asm1 $out.$asm1_name.*.phased_block.bed $asm2 $out.$asm2_name.*.phased_block.bed $out

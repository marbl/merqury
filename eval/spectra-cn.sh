#!/bin/bash

echo "Usage: spectra-cn.sh <read.meryl> <asm1.fasta> [asm2.fasta] out-prefix"
echo -e "\t<read.meryl>\t: Generated with meryl count from i.e. illumina wgs reads"
echo -e "\t<asm1.fasta>\t: haplotype 1 assembly. gzipped or not"
echo -e "\t[asm2.fasta]\t: haplotype 2 assembly. gzipped or not"
echo -e "\t<out-prefix>: output prefix. Required."
echo -e "\t\tWhen only <asm1.fasta> is given, results will be generated in haploid mode."
echo -e "\t\tWhen <asm2.fasta> is given, results will be generated for each asm1 asm2 haploid assembly and asm1+asm2 diploid assembly."
echo


if [[ $# -lt 3 ]]; then
  echo "No args provided. Exit."
  exit -1
fi

source $MERQURY/util/util.sh

read=`link $1`
asm1_fa=`link $2`
name=$4

k=`meryl print $read | head -n 2 | tail -n 1 | awk '{print length($1)}'`
echo "Detected k-mer size $k"
echo

if [ -z $name ]; then
  name=$3
  asm2_fa=""
else
  asm2_fa=`link $3`
fi

if [ -s $name ]; then
  echo "$name already exists. Provide a different name."
  exit -1
fi


has_module=$(check_module)
if [[ $has_module -gt 0 ]]; then
  echo "No modules available.."
else
  module load R
fi


asm1=`echo $asm1_fa | sed 's/.fa$//g' | sed 's/.fasta$//g' | sed 's/.fasta.gz$//g' | sed 's/.fa.gz$//g'`

echo "# Get solid k-mers"
$MERQURY/build/filt.sh $read
filt=`cat ${read/.meryl/.filt}`
read_solid=${read/.meryl/}.gt$filt.meryl

echo "=== Generate spectra-cn plots per assemblies and get QV, k-mer completeness ==="
echo
for asm_fa in $asm1_fa $asm2_fa	# will generate only for asm1_fa if asm2_fa is empty
do
  asm=`echo $asm_fa | sed 's/.fa$//g' | sed 's/.fasta$//g' | sed 's/.fasta.gz$//g' | sed 's/.fa.gz$//g'`

  if [ ! -e $asm.meryl ]; then
    echo "# Generate meryl db for $asm"
    meryl count k=$k output ${asm}.meryl $asm_fa
    echo
  fi

  echo "# Collect read counts per asm copies"
  hist=$name.$asm.spectra-cn.hist
  hist_asm_only=$name.$asm.only.hist

  if [[ -s $hist ]]; then
    echo
    echo "*** $hist found. ***"
    echo
  else

    echo -e "Copies\tkmer_multiplicity\tCount" > $hist

    echo "# Read only"
    meryl difference output read.k$k.$asm.0.meryl $read $asm.meryl
    meryl histogram read.k$k.$asm.0.meryl | awk '{print "read-only\t"$0}' >> $hist

    echo "# Copy 1 ~ 4"
    for i in $(seq 1 4)
    do
      echo "Copy = $i .."
      meryl intersect output read.k$k.$asm.$i.meryl $read [ equal-to $i ${asm}.meryl ]
      meryl histogram read.k$k.$asm.$i.meryl | awk -v cn=$i '{print cn"\t"$0}' >> $hist
      rm -r read.k$k.$asm.$i.meryl
      echo
    done

    echo "Copy >4 .."
    meryl intersect output read.k$k.$asm.gt$i.meryl $read [ greater-than $i ${asm}.meryl ]
    meryl histogram read.k$k.$asm.gt$i.meryl | awk -v cn=">$i" '{print cn"\t"$0}' >> $hist
    rm -r read.k$k.$asm.gt$i.meryl
    echo
  fi

  echo "# Copy numbers in k-mers found only in asm"
  meryl difference output $asm.0.meryl ${asm}.meryl $read
  PRESENT=`meryl statistics ${asm}.0.meryl  | head -n4 | tail -n1 | awk '{print $2}'`
  DISTINCT=`meryl statistics ${asm}.0.meryl  | head -n3 | tail -n1 | awk '{print $2}'`
  MULTI=$(($PRESENT-$DISTINCT))
  echo -e "1\t0\t$DISTINCT" > $hist_asm_only
  echo -e "2\t0\t$MULTI" >> $hist_asm_only
  echo

  echo "# Plot $hist"
  echo "\
  Rscript $MERQURY/plot/plot_spectra_cn.R -f $hist -o $name.$asm.spectra-cn -z $hist_asm_only"
  Rscript $MERQURY/plot/plot_spectra_cn.R -f $hist -o $name.$asm.spectra-cn -z $hist_asm_only
  echo

  echo "# QV statistics"
  ASM_ONLY=`meryl statistics ${asm}.0.meryl  | head -n4 | tail -n1 | awk '{print $2}'`
  TOTAL=`meryl statistics ${asm}.meryl  | head -n4 | tail -n1 | awk '{print $2}'`
  ERROR=`echo "$ASM_ONLY $TOTAL" | awk -v k=$k '{print (1-(1-$1/$2)^(1/k))}'`
  QV=`echo "$ASM_ONLY $TOTAL" | awk -v k=$k '{print (-10*log(1-(1-$1/$2)^(1/k))/log(10))}'`
  echo -e "$asm\t$ASM_ONLY\t$TOTAL\t$QV\t$ERROR" >> $name.qv
  echo

  echo "# Per seq QV statistics"
  meryl-lookup -existence -sequence $asm_fa -mers $asm.0.meryl/ | \
  awk -v k=$k '{print $1"\t"$4"\t"$2"\t"(-10*log(1-(1-$4/$2)^(1/k))/log(10))"\t"(1-(1-$4/$2)^(1/k))}' > $name.$asm.qv
  echo

  echo "# k-mer completeness (recoveray rate) with solid k-mers for $asm with > $filt counts"
  meryl intersect output $asm.solid.meryl $asm.meryl $read_solid
  TOTAL=`meryl statistics $read_solid | head -n3 | tail -n1 | awk '{print $2}'`
  ASM=`meryl statistics $asm.solid.meryl | head -n3 | tail -n1 | awk '{print $2}'`
  echo -e "${asm}\tall\t${ASM}\t${TOTAL}" | awk '{print $0"\t"((100*$3)/$4)}' >> $name.completeness.stats
  rm -r $asm.solid.meryl
  echo

  echo "# Generate ${asm}_only.wig"
  if [[ ! -s "${asm}_only.wig" ]]; then
    meryl-lookup -bed -sequence $asm_fa -mers ${asm}.0.meryl > ${asm}_only.bed
    meryl-lookup -wig-depth -sequence $asm_fa -mers ${asm}.0.meryl > ${asm}_only.wig
    echo "${asm}_only.wig generated."
  else
    echo
    echo "*** ${asm}_only.wig found. ***"
  fi
  echo
done

hist_asm_dist_only=$name.dist_only.hist
if [[ "$asm2_fa" = "" ]]; then
  echo "No asm2_fa given. Done."

  hist=$name.spectra-asm.hist

  if [[ -s $hist ]]; then
    echo "*** Found $hist ***"
	else
    echo "# $asm1 only"
    meryl intersect output read.k$k.$asm1.meryl $read ${asm1}.meryl

    echo "# Write output"
    echo -e "Assembly\tkmer_multiplicity\tCount" > $hist
    meryl histogram read.k$k.$asm1.0.meryl | awk '{print "read-only\t"$0}' >> $hist
    meryl histogram read.k$k.$asm1.meryl | awk -v hap="${asm1}" '{print hap"\t"$0}' >> $hist

    echo "# Get asm only for spectra-asm"
    ASM1_ONLY=`meryl statistics ${asm1}.0.meryl | head -n3 | tail -n1 | awk '{print $2}'`
    echo -e "${asm1}\t0\t$ASM1_ONLY" > $hist_asm_dist_only
  fi

  echo "#	Plot $hist"
  echo "\
  Rscript $MERQURY/plot/plot_spectra_cn.R -f $hist -o $name.spectra-asm -z $hist_asm_dist_only"
  Rscript $MERQURY/plot/plot_spectra_cn.R -f $hist -o $name.spectra-asm -z $hist_asm_dist_only
  echo

  echo "# Clean up"
  rm -r ${asm1}.0.meryl read.k$k.$asm1.0.meryl read.k$k.$asm1.meryl $read_solid
  echo "Done!"

  exit 0
fi
asm2=`echo $asm2_fa | sed 's/.fasta$//g' | sed 's/.fa$//g' | sed 's/.fasta.gz$//g' | sed 's/.fa.gz$//g'`
rm -r read.k$k.$asm1.0.meryl read.k$k.$asm2.0.meryl

echo "# Union-sum: ${asm1} + ${asm2} + shared kmer counts (asm)"
meryl union-sum output ${asm1}_${asm2}_union.meryl ${asm1}.meryl ${asm2}.meryl
echo

echo "# k-mer completeness (recovery rate) with solid k-mers for both assemblies with > $filt counts"
meryl intersect output ${asm1}_${asm2}.solid.meryl ${asm1}_${asm2}_union.meryl $read_solid
TOTAL=`meryl statistics $read_solid | head -n3 | tail -n1 | awk '{print $2}'`
ASM=`meryl statistics ${asm1}_${asm2}.solid.meryl | head -n3 | tail -n1 | awk '{print $2}'`
echo -e "both\tall\t${ASM}\t${TOTAL}" | awk '{print $0"\t"((100*$3)/$4)}' >> $name.completeness.stats
rm -r ${asm1}_${asm2}.solid.meryl $read_solid
echo

echo "# 0-counts in the asm; only seen in the reads"
meryl difference output read.k$k.0.meryl $read ${asm1}_${asm2}_union.meryl
echo

hist=$name.spectra-cn.hist
hist_asm_only=$name.only.hist
hist_asm_dist_only=$name.dist_only.hist

echo
echo "# Generate $hist for combined $asm1_fa and $asm2_fa:"
echo "\"Is my diploid assembly having k-mers in expected copy numbers?\""
echo

if [[ -s $hist ]]; then
  echo
  echo "*** $hist found. Skip k-mer counting per copy numbers ***"
  echo
else
  echo -e "Copies\tkmer_multiplicity\tCount" > $hist
  meryl histogram read.k$k.0.meryl | awk '{print "read-only\t"$0}' >> $hist
  for i in $(seq 1 4)
  do
    echo "Copy = 1 .."
    meryl intersect output read.k$k.$i.meryl $read [ equal-to $i ${asm1}_${asm2}_union.meryl ]
    meryl histogram read.k$k.$i.meryl | awk -v cn=$i '{print cn"\t"$0}' >> $hist
    rm -r read.k$k.$i.meryl
    echo
  done

  echo "Copy >4 .."
  meryl intersect output read.k$k.gt$i.meryl $read [ greater-than $i ${asm1}_${asm2}_union.meryl ]
  meryl histogram read.k$k.gt$i.meryl | awk -v cn=">$i" '{print cn"\t"$0}' >> $hist
  rm -r read.k$k.gt$i.meryl
  echo
fi

echo "# Count k-mers only seen in the assemblies, not in the reads"
meryl difference output ${asm1}_or_${asm2}.0.meryl ${asm1}_${asm2}_union.meryl $read
meryl intersect output ${asm1}_and_${asm2}.0.meryl ${asm1}.0.meryl ${asm2}.0.meryl	# shared
meryl difference output ${asm1}.0.only.meryl $asm1.0.meryl $asm2.0.meryl	# asm1.0 only
meryl difference output ${asm2}.0.only.meryl $asm2.0.meryl $asm1.0.meryl	# asm2.0 only
echo

echo "# Get asm only for spectra-cn"
PRESENT=` meryl statistics ${asm1}_or_${asm2}.0.meryl | head -n4 | tail -n1 | awk '{print $2}'`
DISTINCT=`meryl statistics ${asm1}_or_${asm2}.0.meryl | head -n3 | tail -n1 | awk '{print $2}'`
MULTI=$(($PRESENT-$DISTINCT))
echo -e "1\t0\t$DISTINCT" > $hist_asm_only
echo -e "2\t0\t$MULTI" >> $hist_asm_only
echo

echo "# Get asm only for spectra-asm"
ASM1_ONLY=`meryl statistics ${asm1}.0.only.meryl | head -n3 | tail -n1 | awk '{print $2}'`
ASM2_ONLY=`meryl statistics ${asm2}.0.only.meryl | head -n3 | tail -n1 | awk '{print $2}'`
SHARED=`meryl statistics ${asm1}_and_${asm2}.0.meryl | head -n3 | tail -n1 | awk '{print $2}'`
echo -e "${asm1}-only\t0\t$ASM1_ONLY" > $hist_asm_dist_only
echo -e "${asm2}-only\t0\t$ASM2_ONLY" >> $hist_asm_dist_only
echo -e "shared\t0\t$SHARED" >> $hist_asm_dist_only
rm -r ${asm1}.0.only.meryl ${asm2}.0.only.meryl
echo

echo "# Plot $hist"
echo "\
Rscript $MERQURY/plot/plot_spectra_cn.R -f $hist -o $name.spectra-cn -z $hist_asm_only"
Rscript $MERQURY/plot/plot_spectra_cn.R -f $hist -o $name.spectra-cn -z $hist_asm_only
echo

echo "# QV"
ASM_ONLY=`meryl statistics ${asm1}_or_${asm2}.0.meryl  | head -n4 | tail -n1 | awk '{print $2}'`
TOTAL=`meryl statistics ${asm1}_${asm2}_union.meryl | head -n4 | tail -n1 | awk '{print $2}'`
ERROR=`echo "$ASM_ONLY $TOTAL" | awk -v k=$k '{print (1-(1-$1/$2)^(1/k))}'`
QV=`echo "$ASM_ONLY $TOTAL" | awk -v k=$k '{print (-10*log(1-(1-$1/$2)^(1/k))/log(10))}'`
echo -e "Both\t$ASM_ONLY\t$TOTAL\t$QV\t$ERROR" >> $name.qv
rm -r ${asm1}_and_${asm2}.0.meryl ${asm1}_or_${asm2}.0.meryl ${asm1}_${asm2}_union.meryl ${asm1}.0.meryl ${asm2}.0.meryl
echo

echo "=== Generate spectra-asm.hist for combined $asm1_fa and $asm2_fa ==="
echo "\"Is the assembled distinct portion bigger in one of the two assemblies?\""


hist=$name.spectra-asm.hist

if [[ -e $hist ]]; then
  echo
  echo "*** Found $hist. Skip re-computing. ***"
  echo
else
  echo "# Get ${asm1} / ${asm2} / shared kmers"
  meryl difference output ${asm2}_only.meryl ${asm2}.meryl ${asm1}.meryl
  meryl difference output ${asm1}_only.meryl ${asm1}.meryl ${asm2}.meryl
  meryl intersect output ${asm1}_shrd.meryl ${asm1}.meryl ${asm2}.meryl
  echo

  echo "# $asm1 only"
  meryl intersect output read.k$k.$asm1.meryl $read ${asm1}_only.meryl
  echo

  echo "# $asm2 only"
  meryl intersect output read.k$k.$asm2.meryl $read ${asm2}_only.meryl
  echo

  echo "# shared ($asm1 and $asm2)"
  meryl intersect output read.k$k.shrd.meryl $read ${asm1}_shrd.meryl
  echo

  echo "# Write output"
  echo -e "Assembly\tkmer_multiplicity\tCount" > $hist
  meryl histogram read.k$k.0.meryl | awk '{print "read-only\t"$0}' >> $hist
  meryl histogram read.k$k.$asm1.meryl | awk -v hap="$asm1-only" '{print hap"\t"$0}' >> $hist
  meryl histogram read.k$k.$asm2.meryl | awk -v hap="$asm2-only" '{print hap"\t"$0}' >> $hist
  meryl histogram read.k$k.shrd.meryl | awk -v hap="shared" '{print hap"\t"$0}' >> $hist
  echo
fi

echo "Plot $hist"
echo "\
Rscript $MERQURY/plot/plot_spectra_cn.R -f $hist -o $name.spectra-asm -z $hist_asm_dist_only"
Rscript $MERQURY/plot/plot_spectra_cn.R -f $hist -o $name.spectra-asm -z $hist_asm_dist_only
echo

echo "Clean up"
rm -r read.k$k.0.meryl read.k$k.$asm1.meryl read.k$k.$asm2.meryl read.k$k.shrd.meryl ${asm1}_only.meryl ${asm2}_only.meryl ${asm1}_shrd.meryl
echo

echo "Done!"

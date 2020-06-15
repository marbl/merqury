#!/bin/bash

if [[ "$#" -lt 4 ]]; then
echo "Usage: ./merqury-mash.sh <k-size> <asm.fasta> <input_fofn> <cpus>"
echo
echo "This is the fast version of QV estimates using mash."
echo "The QVs are not completely agreeing with the one obtained with the full merqury run,"
echo "but is more designed to help give a quick estimate of the assembly QV."
exit 0
fi

k=$1
asm=$2
input_fofn=$3
cpus=$4

name=`echo $asm | sed 's/.fasta$//g' | sed 's/.fa$//g' | sed 's/.fasta.gz//g' | sed 's/.fa.gz//g'`

source $MERQURY/util/util.sh

has_module=$(check_module)
if [[ $has_module -gt 0 ]]; then
        echo "No modules available.."
else
        module load mash
fi

mash sketch -s 1000000 -k $k $asm
mash screen -p $cpus $asm.msh `cat $input_fofn | tr '\n' ' '` > $name.msh.idy
cat $name.msh.idy  | awk -v name=$name '{print name"\t"$2"\t"-10*log(1-$1)/log(10)"\t"(1-$1)}' | tr '/' '\t' > $name.msh.qv



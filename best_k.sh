#!/bin/bash

if [ -z $1 ]; then
	echo "Usage: ./best_k.sh <genome_size> [tolerable_collision_rate]"
	echo -e "\t<genome_size>: Haploid genome size or diploid genome size, depending on what we evaluate. In bp."
	echo -e "\t[tolerable_collision_rate]: Error rate in the read set. DEFAULT=0.001 for illumina WGS"
	echo -e "\tSee Fofanov et al. Bioinformatics, 2004 for more details."
	echo
	exit -1
fi

if [ ! -z $2 ]; then
	e=$2
else
	e=0.001
fi

g=$1

echo "genome: $g"
echo "tolerable collision rate: $e"
k=`echo $g $e | awk '{print $1"\t"(1-$2)/$2}' | awk '{print log($1*$2)/log(4)}'`
echo $k

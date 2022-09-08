#!/usr/bin/env bash

if [ -z $1 ]; then
  echo "Usage: ./best_k.sh [-c] <genome_size> [tolerable_collision_rate]"
  echo -e "  -c         : [OPTIONAL] evaluation will be on homopolymer compressed genome. EXPERIMENTAL"
  echo -e "  genome_size: Haploid genome size or diploid genome size, depending on what we evaluate. In bp."
  echo -e "  tolerable_collision_rate: [OPTIONAL] Error rate in the read set. DEFAULT=0.001 for illumina WGS"
  echo -e "See Fofanov et al. Bioinformatics, 2004 for more details."
  echo
  exit -1
fi

if [ "x$1" = "x-c" ]; then
  compress="1"
  shift
fi

if [ ! -z $2 ]; then
	e=$2
else
	e=0.001
fi

g=$1

echo "genome: $g"
echo "tolerable collision rate: $e"
if [[ -z $compress ]]; then
  n=4;
else
  n=3;
fi
k=`echo $g $e | awk '{print $1"\t"(1-$2)/$2}' | awk -v n=$n '{print log($1*$2)/log(n)}'`
echo $k

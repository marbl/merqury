#!/bin/bash

if [[ "$#" -lt 2 ]]; then
  echo "Usage: sh to_hist_for_plotting.sh db1.meryl name1 [ db2.meryl name2 ... ]"
  echo -e "\tstdout: a histogram, accepted by \$MERQURY/plot/plot_spectra_cn.R"
  exit -1
fi

echo -e "kmer\tkmer_multiplicity\tCount"

isDB=true;
db="";

for input in ${1:+"$@"}
do
  if [[ $isDB == true ]]; then
    db=$input;
    isDB=false;
  else
    name=$input;
    meryl histogram $db | awk -v name=$name '{print name"\t"$1"\t"$2}';
    isDB=true;
  fi
done


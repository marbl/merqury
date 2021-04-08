#!/bin/bash

if [[ "$#" -lt 2 ]]; then
	echo
	echo "Usage: hapmers.sh <hap1.meryl> <hap2.meryl> [child.meryl] [-no-filt]"
	echo -e "\t<hap1.meryl>\tHaplotype1 k-mers (all, ex. maternal)"
	echo -e "\t<hap2.meryl>\tHaplotype2 k-mers (all, ex. paternal)"
	echo -e "\t[child.meryl]\tChilds' k-mers (all, from WGS reads)"
  echo -e "\t-no-filt\tDo not filter parental kmers.\n\t\tUse only if parental dbs aren't from regular sequencing dbs"
	echo
	echo -e "\tOutput"
	echo -e "\t\thap1.only.meryl\tHaplotype1 specific k-mers (parental)"
	echo -e "\t\thap2.only.meryl\tHaplotype2 specific k-mers (parental)"
	echo -e "\t\tshrd.meryl\tShared k-mers"
	echo
	echo -e "\tOutput (when [child.meryl is given)"
	echo -e "\t\thap1.hapmer.meryl\tHaplotype1, inherited k-mers (ex. maternal hap-mers)"
	echo -e "\t\thap2.hapmer.meryl\tHaplotype2, inherited k-mers (ex. paternal hap-mers)"
	echo -e "\t\tshrd.inherited.meryl\tShared, inherited k-mers"
	echo
	echo -e "\t*Build each .meryl dbs using the same k-size"
	echo
	exit -1
fi

source $MERQURY/util/util.sh

hap1_meryl=`link $1`
hap2_meryl=`link $2`
if ! [[ "$3" == "-no-filt" ]]; then
  child_meryl=`link $3`
fi
if [[ "${@: -1}" == "-no-filt" ]]; then
  nofilt="-no-filt"
fi

hap1=${hap1_meryl%.meryl*}
hap2=${hap2_meryl%.meryl*}

echo "# Maternal specific k-mers"
if [[ -e $hap1.only.meryl ]]; then
	echo "*** Found hap1.only.meryl. ***"
else
	bash $MERQURY/build/diff.sh $hap1_meryl $hap2_meryl $hap1.only $nofilt
fi
echo

echo "# Paternal specific k-mers"
if [[ -e $hap2.only.meryl ]]; then
        echo "*** Found hap2.only.meryl. ***"
else
	bash $MERQURY/build/diff.sh $hap2_meryl $hap1_meryl $hap2.only $nofilt
fi
echo

echo "# Shared k-mers"
if [[ -e shrd.meryl ]]; then
        echo "*** Found shrd.meryl. ***"
else
	bash $MERQURY/build/intersect.sh $hap1_meryl $hap2_meryl shrd
fi
echo

if [[ -z $child_meryl ]]; then
	echo "No child.meryl given. Done!"
	exit 0
fi

child=${child_meryl/.meryl}

echo "# $hap1 hap-mers"
if [[ -e $hap1.hapmer.meryl ]]; then
        echo "*** Found $hap1.inherited.meryl. ***"
else
	bash $MERQURY/build/intersect.sh $child_meryl $hap1.only.meryl $hap1.inherited
	bash $MERQURY/build/filt.sh $hap1.inherited.meryl $hap1.hapmer
fi
echo

echo -e "$hap1\t"`cat $hap1.inherited.filt` > cutoffs.txt

echo "# $hap2 hap-mers"
if [[ -e $hap2.hapmer.meryl ]]; then
        echo "*** Found hap2.inherited.meryl. ***"
else
	bash $MERQURY/build/intersect.sh $child_meryl $hap2.only.meryl $hap2.inherited
	bash $MERQURY/build/filt.sh $hap2.inherited.meryl $hap2.hapmer
fi
echo

echo -e "$hap2\t"`cat $hap2.inherited.filt` >> cutoffs.txt

echo "# Shared k-mers"
if [[ -e shrd.filt.meryl ]]; then
        echo "*** Found shrd.inherited.meryl. ***"
else
	bash $MERQURY/build/intersect.sh $child_meryl shrd.meryl shrd.inherited
	bash $MERQURY/build/filt.sh shrd.inherited.meryl shrd.filt
fi
echo

echo -e "shared\t"`cat shrd.inherited.filt` >> cutoffs.txt

echo "# Read only"
if [[ -e read.only.meryl ]]; then
	echo "*** Found read.only.meryl ***"
else
	meryl union-sum output $child.inherited.meryl $hap1.inherited.meryl $hap2.inherited.meryl shrd.inherited.meryl
	meryl difference output read.only.meryl $child_meryl $child.inherited.meryl
fi
echo

echo "# Get histogram"
hist=inherited_hapmers.hist
echo -e "k-mer\tkmer_multiplicity\tCount" > $hist
meryl histogram read.only.meryl | awk -v kmer="read-only" '{print kmer"\t"$1"\t"$2}' >> $hist
meryl histogram $hap1.inherited.meryl | awk -v kmer="$hap1" '{print kmer"\t"$1"\t"$2}' >> $hist
meryl histogram $hap2.inherited.meryl | awk -v kmer="$hap2" '{print kmer"\t"$1"\t"$2}' >> $hist
meryl histogram shrd.inherited.meryl | awk -v kmer="shared" '{print kmer"\t"$1"\t"$2}' >> $hist
echo

echo "# Plot $hist"
source $MERQURY/util/util.sh

has_module=$(check_module)
if [[ $has_module -gt 0 ]]; then
        echo "No modules available.."
else
	module load R
fi
echo

Rscript $MERQURY/plot/plot_spectra_cn.R -f $hist -o ${hist/.hist/} -l cutoffs.txt
echo

echo "Done!"


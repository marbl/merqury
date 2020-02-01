#!/bin/bash

if [[ "$#" -lt 3 ]]; then
	echo
	echo "Usage: hapmers.sh <mat.meryl> <pat.meryl> [child.meryl]"
	echo -e "\t<mat.meryl>\tMaternal k-mers (all)"
	echo -e "\t<pat.meryl>\tPaternal k-mers (all)"
	echo -e "\t[child.meryl]\tChilds' k-mers (all, from WGS reads)"
	echo
	echo -e "\tOutput"
	echo -e "\t\tmat.only.meryl\tMaternal specific k-mers"
	echo -e "\t\tpat.only.meryl\tPaternal specific k-mers"
	echo -e "\t\tshrd.meryl\tShared k-mers"
	echo
	echo -e "\tOutput (when [child.meryl is given)"
	echo -e "\t\tmat.inherited.meryl\tMaternal, inherited k-mers (maternal hap-mers)"
	echo -e "\t\tpat.inherited.meryl\tPaternal, inherited k-mers (maternal hap-mers)"
	echo -e "\t\tshrd.inherited.meryl\tShared, inherited k-mers"
	echo
	echo -e "\t*Build each .meryl dbs using the same k-size"
	echo
	exit -1
fi

mat_meryl=$1
pat_meryl=$2
child_meryl=$3

mat=${mat_meryl/.meryl/}
pat=${pat_meryl/.meryl/}

echo "# Maternal specific k-mers"
if [[ -e mat.only.meryl ]]; then
	echo "*** Found mat.only.meryl. ***"
else
	sh $MERQURY/build/diff.sh $mat_meryl $pat_meryl mat.only
fi
echo

echo "# Paternal specific k-mers"
if [[ -e pat.only.meryl ]]; then
        echo "*** Found pat.only.meryl. ***"
else
	sh $MERQURY/build/diff.sh $pat_meryl $mat_meryl pat.only
fi
echo

echo "# Shared k-mers"
if [[ -e shrd.meryl ]]; then
        echo "*** Found shrd.meryl. ***"
else
	sh $MERQURY/build/intersect.sh $mat_meryl $pat_meryl shrd
fi
echo

if [[ -z $child_meryl ]]; then
	echo "No child.meryl given. Done!"
	exit 0
fi

child=${child_meryl/.meryl}

echo "# Maternal hap-mers"
if [[ -e mat.hapmer.meryl ]]; then
        echo "*** Found mat.inherited.meryl. ***"
else
	sh $MERQURY/build/intersect.sh $child_meryl mat.only.meryl mat.inherited
	sh $MERQURY/build/filt.sh mat.inherited.meryl mat.hapmer
fi
echo

echo "# Paternal hap-mers"
if [[ -e pat.hapmer.meryl ]]; then
        echo "*** Found pat.inherited.meryl. ***"
else
	sh $MERQURY/build/intersect.sh $child_meryl pat.only.meryl pat.inherited
	sh $MERQURY/build/filt.sh pat.inherited.meryl pat.hapmer
fi
echo

echo "# Shared k-mers"
if [[ -e shrd.filt.meryl ]]; then
        echo "*** Found shrd.inherited.meryl. ***"
else
	sh $MERQURY/build/intersect.sh $child_meryl shrd.meryl shrd.inherited
	sh $MERQURY/build/filt.sh shrd.inherited.meryl shrd.filt
fi
echo

echo "# Read only"
if [[ -e read.only.meryl ]]; then
	echo "*** Found read.only.meryl ***"
else
	meryl union-sum output $child.inherited.meryl mat.inherited.meryl pat.inherited.meryl shrd.inherited.meryl
	meryl difference output read.only.meryl $child_meryl $child.inherited.meryl
fi
echo

echo "# Get histogram"
hist=inherited_hapmers.hist
echo -e "k-mer\tkmer_multiplicity\tCount" > $hist
meryl histogram read.only.meryl | awk -v kmer="read-only" '{print kmer"\t"$1"\t"$2}' >> $hist
meryl histogram mat.inherited.meryl | awk -v kmer="mat" '{print kmer"\t"$1"\t"$2}' >> $hist
meryl histogram pat.inherited.meryl | awk -v kmer="pat" '{print kmer"\t"$1"\t"$2}' >> $hist
meryl histogram shrd.inherited.meryl | awk -v kmer="shared" '{print kmer"\t"$1"\t"$2}' >> $hist
echo

echo "# Plot $hist"
## Comment this line if R is properly installed ##
echo "Load R"					 #
module load R                                    #
##################################################
echo

Rscript $MERQURY/plot/plot_spectra_cn.R -f $hist -o ${hist/.hist/}
echo

echo "Done!"


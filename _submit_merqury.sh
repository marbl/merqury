#! /bin/bash

if [[ "$#" -lt 4 ]]; then
	echo
        echo "Usage: _submit_merqury.sh <read-db.meryl> [<mat.meryl> <pat.meryl>] <k> <asm1.fasta> [asm2.fasta] <out>"
	echo
	echo "***Submitter script to run each steps in parallele on slurm. Modify according to your cluster environment.***"
	echo
        echo -e "\t<read-db.meryl>\t: k-mer counts of the read set"
        echo -e "\t<mat.meryl>\t: k-mer counts of the maternal haplotype (ex. mat.inherited.meryl)"
        echo -e "\t<pat.meryl>\t: k-mer counts of the paternal haplotype (ex. pat.inherited.meryl)"
        echo -e "\t<k>\t\t: k-mer size"
        echo -e "\t<asm1.fasta>\t: Assembly fasta file (ex. pri.fasta, hap1.fasta or maternal.fasta)"
        echo -e "\t[asm2.fasta]\t: Additional fasta file (ex. alt.fasta, hap2.fasta or paternal.fasta)"
        echo -e "\t\t\t*asm1.meryl and asm2.meryl will be generated. Avoid using the same names as the hap-mer dbs"
        echo -e "\t<out>\t\t: Output prefix"
        echo -e "Arang Rhie, 2020-01-29. arrhie@gmail.com"
        exit 0
fi

readdb=$1

if [[ "$#" -gt 5 ]]; then
        echo "Haplotype dbs provided."
        echo "Running Merqury in trio mode..."
        hap1=$2
        hap2=$3
        k=$4
        asm1=$5
        if [[ "$#" -eq 6 ]]; then
                out=$6
        else
                asm2=$6
                out=$7
        fi
elif [[ "$#" -gt 3 ]]; then
        echo "No haplotype dbs provided."
        echo "Running Merqury in non-trio mode..."
        k=$2
        asm1=$3
        if [[ "$#" -eq 4 ]]; then
                out=$4
        else
                asm2=$4
                out=$5
        fi
fi

if [ -e $out ]; then
        echo "$out already exists. Provide a different name. (Are we missing the <out>?)"
        exit -1
fi



mkdir -p logs

# All jobs are expected to finish within 4 hours
partition=quick
walltime=4:00:00
path=`pwd`
extra=""



#### Get spectra-cn plots and QV stats
cpus=32
mem=48g
name=$out.spectra-cn
script="$MERQURY/eval/spectra-cn.sh"
args="$readdb $k $asm1 $asm2 $out"
log=logs/$name.%A.log

echo "\
sbatch -J $name --mem=$mem --partition=$partition --cpus-per-task=$cpus -D $path $extra --time=$walltime --error=$log --output=$log $script $args"
sbatch -J $name --mem=$mem --partition=$partition --cpus-per-task=$cpus -D $path $extra --time=$walltime --error=$log --output=$log $script $args > cn.jid
jid=`cat cn.jid`

if [ -z $hap1 ]; then
	exit 0
fi


#### Get blob plots
cpus=8
mem=10g

script="$MERQURY/trio/hap_blob.sh"
# ./hap_blob.sh <hap1.meryl> <hap2.meryl> <asm1.fasta> [asm2.fasta] <out>
args="$hap1 $hap2 $asm1 $asm2 $out"
name=$out.blob
log=logs/$name.%A.log

echo "\
sbatch -J $name --mem=$mem --partition=$partition --cpus-per-task=$cpus -D $path $extra --time=$walltime --error=$log --output=$log $script $args"
sbatch -J $name --mem=$mem --partition=$partition --cpus-per-task=$cpus -D $path $extra --time=$walltime --error=$log --output=$log $script $args > blob.jid


#### Get haplotype specfic spectra-cn plots
cpus=24
mem=10g
extra="--dependency=afterok:$jid"	# Re-uses asm.meryl dbs in spectra-cn.sh.

name=$out.spectra-hap
script="$MERQURY/trio/spectra-hap.sh"
args="$readdb $hap1 $hap2 $k $asm1 $asm2 $out"
log=logs/$name.%A.log

echo "\
sbatch -J $name --mem=$mem --partition=$partition --cpus-per-task=$cpus -D $path $extra --time=$walltime --error=$log --output=$log $script $args"
sbatch -J $name --mem=$mem --partition=$partition --cpus-per-task=$cpus -D $path $extra --time=$walltime --error=$log --output=$log $script $args > hap.jid

#### Get phase blocks
cpus=12
mem=72g
extra=""

script="$MERQURY/trio/phase_block.sh"
# ./phase_block.sh <asm.fasta> <mat.meryl> <pat.meryl> <out>


if [[ "$asm2" == "" ]] ; then
	# Only one assembly given.
	args="$asm1 $hap1 $hap2 $out"
        name=$out.phase-block
else
	args="$asm1 $hap1 $hap2 $out.${asm1/.fasta/}"
	name=$out.phase-block.${asm1/.fasta/}
fi
log=logs/$name.%A.log

echo "\
sbatch -J $name --mem=$mem --partition=$partition --cpus-per-task=$cpus -D $path $extra --time=$walltime --error=$log --output=$log $script $args"
sbatch -J $name --mem=$mem --partition=$partition --cpus-per-task=$cpus -D $path $extra --time=$walltime --error=$log --output=$log $script $args > block1.jid

if [[ "$asm2" == "" ]] ; then
	exit 0
fi

args="$asm2 $hap1 $hap2 $out.${asm2/.fasta/}"
name=$out.phase-block.${asm2/.fasta/}
log=logs/$name.%A.log

echo "\
sbatch -J $name --mem=$mem --partition=$partition --cpus-per-task=$cpus -D $path $extra --time=$walltime --error=$log --output=$log $script $args"
sbatch -J $name --mem=$mem --partition=$partition --cpus-per-task=$cpus -D $path $extra --time=$walltime --error=$log --output=$log $script $args > block2.jid


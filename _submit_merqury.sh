#! /bin/bash

if [[ "$#" -lt 3 ]]; then
	echo
        echo "Usage: _submit_merqury.sh <read-db.meryl> [<mat.meryl> <pat.meryl>] <asm1.fasta> [asm2.fasta] <out>"
	echo
	echo "***Submitter script to run each steps in parallele on slurm. Modify according to your cluster environment.***"
	echo
        echo -e "\t<read-db.meryl>\t: k-mer counts of the read set"
        echo -e "\t<mat.meryl>\t: k-mer counts of the maternal haplotype (ex. mat.hapmer.meryl)"
        echo -e "\t<pat.meryl>\t: k-mer counts of the paternal haplotype (ex. pat.hapmer.meryl)"
        echo -e "\t<asm1.fasta>\t: Assembly fasta file (ex. pri.fasta, hap1.fasta or maternal.fasta)"
        echo -e "\t[asm2.fasta]\t: Additional fasta file (ex. alt.fasta, hap2.fasta or paternal.fasta)"
        echo -e "\t\t\t*asm1.meryl and asm2.meryl will be generated. Avoid using the same names as the hap-mer dbs"
        echo -e "\t<out>\t\t: Output prefix"
        echo -e "Arang Rhie, 2020-01-29. arrhie@gmail.com"
        exit 0
fi

source $MERQURY/util/util.sh

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

# All jobs are expected to finish within 4 hours, giving more time for large genomes (>5GB)
partition=norm
walltime=8:00:00
path=`pwd`
extra=""



#### Get spectra-cn plots and QV stats
cpus=24
mem=24g
name=$out.spectra-cn
script="$MERQURY/eval/spectra-cn.sh"
args="$readdb $asm1 $asm2 $out"
log=logs/$name.%A.log

echo "\
sbatch -J $name --mem=$mem --partition=$partition --cpus-per-task=$cpus -D $path $extra --time=$walltime --error=$log --output=$log $script $args"
sbatch -J $name --mem=$mem --partition=$partition --cpus-per-task=$cpus -D $path $extra --time=$walltime --error=$log --output=$log $script $args > cn.jid
jid=`cat cn.jid`

if [ -z $hap1 ]; then
	exit 0
fi

# All below jobs are expected to finish within 4 hours
partition=quick
walltime=4:00:00

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
args="$readdb $hap1 $hap2 $asm1 $asm2 $out"
log=logs/$name.%A.log

echo "\
sbatch -J $name --mem=$mem --partition=$partition --cpus-per-task=$cpus -D $path $extra --time=$walltime --error=$log --output=$log $script $args"
sbatch -J $name --mem=$mem --partition=$partition --cpus-per-task=$cpus -D $path $extra --time=$walltime --error=$log --output=$log $script $args > hap.jid

#### Get phase blocks
# This may take longer
partition=norm
walltime=12:00:00

cpus=24
mem=24g
extra=""

script="$MERQURY/trio/phase_block.sh"
# ./phase_block.sh <asm.fasta> <mat.meryl> <pat.meryl> <out>


# Only one assembly given.
args="$asm1 $hap1 $hap2 $out.${asm1/.fasta/}"
name=$out.phase-block.${asm1/.fasta/}
log=logs/$name.%A.log

echo "\
sbatch -J $name --mem=$mem --partition=$partition --cpus-per-task=$cpus -D $path $extra --time=$walltime --error=$log --output=$log $script $args"
sbatch -J $name --mem=$mem --partition=$partition --cpus-per-task=$cpus -D $path $extra --time=$walltime --error=$log --output=$log $script $args > block1.jid

if [[ "$asm2" == "" ]] ; then
	# Compute block stats
  partition=quick
  walltime=1:00:00

	cpus=4
	mem=8g
	name="$out.block_N1"
	log=logs/$name.%A.log
	extra="--dependency=afterok:`cat block1.jid`"

	# ./block_n_stats.sh <asm1.fasta> <asm1.*.phased_block.bed> [<asm2.fasta> <asm2.*.phased_block.bed>] <out> [genome_size]
	script="$MERQURY/trio/block_n_stats.sh"
	args="$asm1 $out.${asm1/.fasta/}.*.phased_block.bed $out"

	echo "\
	sbatch -J $name --mem=$mem --partition=$partition --cpus-per-task=$cpus -D $path $extra --time=$walltime --error=$log --output=$log $script $args"
	sbatch -J $name --mem=$mem --partition=$partition --cpus-per-task=$cpus -D $path $extra --time=$walltime --error=$log --output=$log $script $args > block1_N.jid
	exit 0
fi

cpus=24
mem=24g
extra=""
args="$asm2 $hap1 $hap2 $out.${asm2/.fasta/}"
name=$out.phase-block.${asm2/.fasta/}
log=logs/$name.%A.log

echo "\
sbatch -J $name --mem=$mem --partition=$partition --cpus-per-task=$cpus -D $path $extra --time=$walltime --error=$log --output=$log $script $args"
sbatch -J $name --mem=$mem --partition=$partition --cpus-per-task=$cpus -D $path $extra --time=$walltime --error=$log --output=$log $script $args > block2.jid

# Compute block stats
partition=quick
walltime=1:00:00

cpus=4
mem=8g
extra="--dependency=afterok:`cat block1.jid`,afterok:`cat block2.jid`"

# ./block_n_stats.sh <asm1.fasta> <asm1.*.phased_block.bed> [<asm2.fasta> <asm2.*.phased_block.bed>] <out> [genome_size]
script="$MERQURY/trio/block_n_stats.sh"
args="$asm1 $out.${asm1/.fasta/}.*.phased_block.bed $asm2 $out.${asm2/.fasta/}.*.phased_block.bed $out"
name=$out.block_N
log=logs/$name.%A.log

echo "\
sbatch -J $name --mem=$mem --partition=$partition --cpus-per-task=$cpus -D $path $extra --time=$walltime --error=$log --output=$log $script $args"
sbatch -J $name --mem=$mem --partition=$partition --cpus-per-task=$cpus -D $path $extra --time=$walltime --error=$log --output=$log $script $args > block2_N.jid


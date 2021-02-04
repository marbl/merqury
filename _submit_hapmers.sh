#!/bin/bash

if [[ "$#" -lt 2 ]]; then
    echo "Usage: ./_submit_hapmers.sh <mat.meryl> <pat.meryl> [child.meryl]"
    echo -e "\t<mat.meryl>:\tmeryl db of the maternal read set"
    echo -e "\t<pat.meryl>:\tmeryl db of the paternal read set"
    echo -e "\t[child.meryl]:\tmeryl db of the child read set"
    echo
    echo -e "\t\t\tThe parental hap-mers will be linked as"
    echo -e "\t\t\t - mat_only.meryl"
    echo -e "\t\t\t - pat_only.meryl"
    echo
    echo -e "\t\t\tWhen child.meryl is provided, inherited hap-mers will be linked as"
    echo -e "\t\t\t - mat.inherited.meryl"
    echo -e "\t\t\t - pat.inherited.meryl"
    echo
    echo -e "\t\t\tUse the followings for evaluating trios"
    echo -e "\t\t\t - mat.hapmer.meryl"
    echo -e "\t\t\t - pat.hapmer.meryl"
    exit -1
fi

mat_meryl=$1
pat_meryl=$2
child_meryl=$3

mkdir -p logs

cpus=16 # Max: 64 per each .meryl/ file writer
mem=24g
partition=quick
walltime=3:00:00
name=hapmers
script=$MERQURY/trio/hapmers.sh
args="$mat_meryl $pat_meryl $child_meryl"
log=logs/$name.%A.log

echo "\
sbatch -J $name --mem=$mem --partition=$partition --cpus-per-task=$cpus -D `pwd` --time=$walltime --error=$log --output=$log $script $args"
sbatch -J $name --mem=$mem --partition=$partition --cpus-per-task=$cpus -D `pwd` --time=$walltime --error=$log --output=$log $script $args


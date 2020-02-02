# Merqury

## Evaluate genome assemblies with k-mers and more

Often, genome assembly projects have illumina whole genome sequencing reads available for the assembled individual.
The k-mer spectrum of this read set can be used for independently evaluating assembly quality without the need of a high quality reference.
Merqury provides a set of tools for this purpose.

## Dependency
* gcc 4.8 or higher
* meryl
* Java run time environment (JRE)
* R with ggplot2 (tested on R 3.6.1)
* bedtools
* samtools
* igvtools

## Installation

### Get a working meryl in your PATH
```shell
git clone https://github.com/marbl/meryl.git
cd meryl/src
make -j 24
export PATH=/path/to/meryl/…/bin:$PATH
```
See if we get help message for `meryl`.

### Add a path variable MERQURY
```shell
git clone https://github.com/marbl/merqury.git
export MERQURY=$PWD
```
Add the “export” part to your environment (~/.bash_profile or ~/.profile).
Add installation dir paths for `bedtools`, `samtools` and `igvtools` to your enviroenment.
`source` it.


## Run

On a single machine:
```
ln -s $MERQURY/merqury.sh		# Link merqury
./merqury.sh <read-db.meryl> [<mat.meryl> <pat.meryl>] <k> <asm1.fasta> [asm2.fasta] <out>

Usage: merqury.sh <read-db.meryl> [<mat.meryl> <pat.meryl>] <k> <asm1.fasta> [asm2.fasta] <out>
	<read-db.meryl>	: k-mer counts of the read set
	<mat.meryl>		: k-mer counts of the maternal haplotype (ex. mat.only.meryl or mat.hapmer.meryl)
	<pat.meryl>		: k-mer counts of the paternal haplotype (ex. pat.only.meryl or pat.hapmer.meryl)
	<k>			: k size
	<asm1.fasta>	: Assembly fasta file (ex. pri.fasta, hap1.fasta or maternal.fasta)
	[asm2.fasta]	: Additional fasta file (ex. alt.fasta, hap2.fasta or paternal.fasta)
	*asm1.meryl and asm2.meryl will be generated. Avoid using the same names as the hap-mer dbs
	<out>		: Output prefix
```
`< >` : required  
`[ ]` : optional

On a cluster:
```
ln -s $MERQURY/_submit_merqury.sh		# Link merqury
./_submit_merqury.sh <read-db.meryl> [<mat.meryl> <pat.meryl>] <k> <asm1.fasta> [asm2.fasta] <out>
```
* All `_submit_` scripts assume slurm environment. Change the `sbatch` to match your environment.

## Prepare meryl dbs (*[see details](https://github.com/marbl/merqury/wiki/1.-Prepare-meryl-dbs)*)
1. Get the right k size
2. Build k-mer dbs with meryl
3. Build hap-mers for trios

## Outline
1. Overall assembly evaluation
2. Phasing assessment with hap-mers




## Citing merqury

There will be a preprint available soon. Until then, please cite this github repo.



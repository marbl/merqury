# Merqury

## Evaluate genome assemblies with k-mers and more

Often, genome assembly projects have illumina whole genome sequencing reads available for the assembled individual.
The k-mer spectrum of this read set can be used for independently evaluating assembly quality without the need of a high quality reference.
Merqury provides a set of tools for this purpose.

## Dependency
* gcc 4.8 or higher
* meryl
* Java run time environment (JRE)
* R with argparse, ggplot2, and scales (tested on R 3.6.1)
* bedtools
* samtools
* igvtools

## Installation

### Get a working meryl in your PATH
Download meryl release: https://github.com/marbl/meryl/releases/tag/v1.0

If the binary doesn't work, download the source and compile:
```shell
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
./merqury.sh <read-db.meryl> [<mat.meryl> <pat.meryl>] <asm1.fasta> [asm2.fasta] <out>

Usage: merqury.sh <read-db.meryl> [<mat.meryl> <pat.meryl>] <asm1.fasta> [asm2.fasta] <out>
	<read-db.meryl>	: k-mer counts of the read set
	<mat.meryl>		: k-mer counts of the maternal haplotype (ex. mat.only.meryl or mat.hapmer.meryl)
	<pat.meryl>		: k-mer counts of the paternal haplotype (ex. pat.only.meryl or pat.hapmer.meryl)
	<asm1.fasta>	: Assembly fasta file (ex. pri.fasta, hap1.fasta or maternal.fasta)
	[asm2.fasta]	: Additional fasta file (ex. alt.fasta, hap2.fasta or paternal.fasta)
	*asm1.meryl and asm2.meryl will be generated. Avoid using the same names as the hap-mer dbs
	<out>		: Output prefix
```
`< >` : required  
`[ ]` : optional

On a cluster:
```
ln -s $MERQURY/_submit_merqury.sh	# Link merqury
./_submit_merqury.sh <read-db.meryl> [<mat.meryl> <pat.meryl>] <asm1.fasta> [asm2.fasta] <out>
```
* All `_submit_` scripts assume slurm environment. Change the `sbatch` to match your environment.

## 1. Prepare meryl dbs ([details](https://github.com/marbl/merqury/wiki/1.-Prepare-meryl-dbs))
1. Get the right k size
2. Build k-mer dbs with meryl
3. Build hap-mers for trios

## 2. Overall assembly evaluation ([details](https://github.com/marbl/merqury/wiki/2.-Overall-k-mer-evaluation))
1. Reference free QV estimate
2. k-mer completeness (recovery rate)
3. Spectra copy number analysis
4. Track error bases in the assembly

## 3. Phasing assessment with hap-mers ([details](https://github.com/marbl/merqury/wiki/3.-Phasing-assessment-with-hap-mers))
1. Inherited hap-mer plots
2. Hap-mer blob plots
3. Hap-mer completeness (recovery rate)
4. Spectra copy number analysis per hap-mers
5. Phased block statistics and switch error rates
6. Track each haplotype block in the assembly


## Citing merqury

There will be a preprint available soon. Until then, please cite this github repo.



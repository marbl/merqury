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
cd merqury
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


### 1. I have one assembly (pseudo-haplotype or mixed-haplotype)
```shell
# I don't have the hap-mers
./merqury.sh read-db.meryl asm1.fasta out_prefix

# I have the hap-mers
./merqury.sh read-db.meryl mat.meryl pat.meryl asm1.fasta out_prefix
```

### 2. I have two assemblies (diploid)
```shell
# I don't have the hap-mers
./merqury.sh read-db.meryl asm1.fasta asm2.fasta out_prefix

# I have the hap-mers
./merqury.sh read-db.meryl mat.meryl pat.meryl asm1.fasta asm2.fasta out_prefix
```

* Note there is no need to run merqury per-assemblies again. Give two fasta files. Merqury generates stats for each and combined.



### How to parallelize
Merqury starts with `eval/spectra_cn.sh`.
When hap-mers are provided, merqury runs modules under `trio/` in addition to `eval/spectra_cn.sh`.


The following can run at the same time. Modules with dependency are followed by arrows (->).
* `eval/spectra_cn.sh` -> `trio/spectra_hap.sh`
* `trio/hap_blob.sh`
* `trio/phase_block.sh` per assembly -> `trio/block_n_stats.sh`


Meryl, the k-mer counter inside, uses the maximum cpus available.
Set `OMP_NUM_THREADS=24` for example to use 24 threads.

On slurm environment, simply run:
```
ln -s $MERQURY/_submit_merqury.sh	# Link merqury
./_submit_merqury.sh <read-db.meryl> [<mat.meryl> <pat.meryl>] <asm1.fasta> [asm2.fasta] <out>
```
Change the `sbatch` to match your environment. (ex. partition)


## Outputs from each modules
* `eval/spectra_cn.sh`: k-mer completeness, qv, spectra-cn and spectra-asm plots, asm-only `.bed` and `.tdf` for tracking errors
* `eval/qv.sh`: just get the qv stats and quit.
* `trio/spectra_hap.sh`: hap-mer level spectra-cn plots, hap-mer completeness
* `trio/hap_blob.sh`: blob plots of the hap-mers in each contg/scaffold
* `trio/phase_block.sh`: phase block statistics, phase block N* plots, hap-mer tracks (`.bed` and `.tdf` files)
* `trio/block_n_stats.sh`: continuity plots (phase block N* or NG* plots, phase block vs. contig/scaffold plots)
* `trio/switch_error.sh`: this is run part of `phase_blck.sh`, however can be re-run with desired short-range switch parameters. Run `trio/block_n_stats.sh` along with it to get the associated plots.

## Tips for helps
Run each script without any parameters if not sure what to do.
For example, `./trio/switch_error.sh` will give a help message and quit.

Following wiki pages have more detailed examples.

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

## Available pre-built meryl dbs
Meryl dbs from Illumina WGS and hapmers are available [here](https://obj.umiacs.umd.edu/marbl_publications/merqury/index.html) for
* A. thaliana COL-0 x CVI-0 F1
* NA12878 (HG001)
* HG002

## Citing merqury

Please use the following [preprint](https://www.biorxiv.org/content/10.1101/2020.03.15.992941v1) to cite Merqury:

Arang Rhie, Brian P. Walenz, Sergey Koren, Adam M. Phillippy, Merqury: reference-free quality and phasing assessment for genome assemblies, bioRxiv (2020). doi: https://doi.org/10.1101/2020.03.15.992941




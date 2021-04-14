# Merqury

## Evaluate genome assemblies with k-mers and more

Often, genome assembly projects have illumina whole genome sequencing reads available for the assembled individual.<br>
The k-mer spectrum of this read set can be used for independently evaluating assembly quality without the need of a high quality reference.<br>
Merqury provides a set of tools for this purpose.

## Dependency
* gcc 7.4 or higher (for installing meryl)
* [meryl v1.3](https://github.com/marbl/meryl/releases/tag/v1.3)
* Java run time environment (JRE)
* R with argparse, ggplot2, and scales (recommend R 4.0.3+)
* bedtools
* samtools


Note that igvtools is no longer used. The `.tdf` files are replaced with `.wig` files, compatable to IGV and UCSC genome browser.


## Installation

### Stable Release

#### Direct installation 
1. Get a working [Meryl](https://github.com/marbl/meryl) in your PATH


Download meryl release: https://github.com/marbl/meryl/releases/tag/v1.3
```shell
tar -xJf meryl-1.3.*.tar.xz
cd meryl-1.3/bin
export PATH=$pwd:$PATH
```

If the binary doesn't work, download the source and compile:
```shell
cd meryl/src
make -j 24
export PATH=/path/to/meryl/…/bin:$PATH
```
See if we get help message with `meryl`.

2. Download the release version and set env variable `$MERQURY`
```shell
wget https://github.com/marbl/merqury/archive/v1.3.tar.gz
tar -zxvf v1.3.tar.gz
cd merqury-1.3
export MERQURY=$PWD
```
Add the “export” part to your environment for both meryl and MERQURY (~/.bash_profile or ~/.profile).<br>
Add installation dir paths for `bedtools`, `samtools` and `igvtools` to your environment.<br>
`source` it.

#### Through Conda
Thanks to @EdHarry, a conda recipe is now available: https://anaconda.org/bioconda/merqury <br>
On a new conda environment, run:
```shell
conda install -c conda-forge -c bioconda merqury
```

Or, if you have a different version of jdk installed or want to have a separate conda environnment for merqury:
```shell
conda create -n merqury -c conda-forge -c bioconda merqury openjdk=11
```

You will then need to activate the merqury environment before using it with:
```shell
conda activate merqury
```

Test running 
```Shell
Rscript $MERQURY/plot/plot_spectra_cn.R --help
```

In case R complains for version mismatches of the R packages, try
```Shell
conda update --all
```
It seems like R in conda isn't maintained anymore. Try to modify channel priority in `.condarc`.

## Run

* !! Merqury assumes all meryl dbs (dirs) are named with `.meryl`. !!

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

## Example

Below is showing examples how to run Merqury using the prebuilt meryl dbs on a. thaliana F1 hybrid.
The fasta files are the trio-binned assemblies from [Koren et al](https://doi.org/10.1038/nbt.4277).

```shell
### Download assemblies ###
wget https://gembox.cbcb.umd.edu/triobinning/athal_COL.fasta
wget https://gembox.cbcb.umd.edu/triobinning/athal_CVI.fasta

### Download prebuilt meryl dbs ###
# read.meryl of the F1 hybrid between COL-0 and CVI-0
wget https://obj.umiacs.umd.edu/marbl_publications/merqury/athal/a_thal.k18.meryl.tar.gz
# hap-mers for COL-0 haplotype
wget https://obj.umiacs.umd.edu/marbl_publications/merqury/athal/a_thal.col0.hapmer.meryl.tar.gz
# hap-mers for CVI-0 haplotype
wget https://obj.umiacs.umd.edu/marbl_publications/merqury/athal/a_thal.cvi0.hapmer.meryl.tar.gz

# Untar
for gz in *.tar.gz
do
    tar -zxf $gz
done

# Run merqury
$MERQURY/merqury.sh F1.k18.meryl col0.hapmer.meryl cvi0.hapmer.meryl athal_COL.fasta athal_CVI.fasta test
```


### 1. I have one assembly (pseudo-haplotype or mixed-haplotype)
```shell
# I don't have the hap-mers
$MERQURY/merqury.sh read-db.meryl asm1.fasta out_prefix
# Using the example above
$MERQURY/merqury.sh F1.k18.meryl athal_COL.fasta test-1

# I have the hap-mers
$MERQURY/merqury.sh read-db.meryl mat.meryl pat.meryl asm1.fasta out_prefix
# Using the example above
$MERQURY/merqury.sh F1.k18.meryl col0.hapmer.meryl cvi0.hapmer.meryl athal_COL.fasta test-1
```

### 2. I have two assemblies (diploid)
```shell
# I don't have the hap-mers
$MERQURY/merqury.sh read-db.meryl asm1.fasta asm2.fasta out_prefix
# Using the example above
$MERQURY/merqury.sh F1.k18.meryl athal_COL.fasta athal_CVI.fasta test-2

# I have the hap-mers
$MERQURY/merqury.sh read-db.meryl mat.meryl pat.meryl asm1.fasta asm2.fasta out_prefix
# Using the example above
$MERQURY/merqury.sh F1.k18.meryl col0.hapmer.meryl cvi0.hapmer.meryl athal_COL.fasta athal_CVI.fasta test-2
```

* Note there is no need to run merqury per-assemblies. Give two fasta files, Merqury generates stats for each and combined.



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

Please use this [paper](https://doi.org/10.1186/s13059-020-02134-9) to cite Merqury:

Rhie, A., Walenz, B.P., Koren, S. et al. Merqury: reference-free quality, completeness, and phasing assessment for genome assemblies. Genome Biol 21, 245 (2020). https://doi.org/10.1186/s13059-020-02134-9



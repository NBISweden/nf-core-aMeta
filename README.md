# NBISweden/ameta

[![Open in GitHub Codespaces](https://img.shields.io/badge/Open_In_GitHub_Codespaces-black?labelColor=grey&logo=github)](https://github.com/codespaces/new/NBISweden/ameta)
[![GitHub Actions CI Status](https://github.com/NBISweden/ameta/actions/workflows/nf-test.yml/badge.svg)](https://github.com/NBISweden/ameta/actions/workflows/nf-test.yml)
[![GitHub Actions Linting Status](https://github.com/NBISweden/ameta/actions/workflows/linting.yml/badge.svg)](https://github.com/NBISweden/ameta/actions/workflows/linting.yml)[![Cite with Zenodo](http://img.shields.io/badge/DOI-10.5281/zenodo.XXXXXXX-1073c8?labelColor=000000)](https://doi.org/10.5281/zenodo.XXXXXXX)
[![nf-test](https://img.shields.io/badge/unit_tests-nf--test-337ab7.svg)](https://www.nf-test.com)

[![Nextflow](https://img.shields.io/badge/version-%E2%89%A526.4.0-green?style=flat&logo=nextflow&logoColor=white&color=%230DC09D&link=https%3A%2F%2Fnextflow.io)](https://www.nextflow.io/)
[![nf-core template version](https://img.shields.io/badge/nf--core_template-4.0.3-green?style=flat&logo=nfcore&logoColor=white&color=%2324B064&link=https%3A%2F%2Fnf-co.re)](https://github.com/nf-core/tools/releases/tag/4.0.3)
[![run with conda](http://img.shields.io/badge/run%20with-conda-3EB049?labelColor=000000&logo=anaconda)](https://docs.conda.io/en/latest/)
[![run with docker](https://img.shields.io/badge/run%20with-docker-0db7ed?labelColor=000000&logo=docker)](https://www.docker.com/)
[![run with singularity](https://img.shields.io/badge/run%20with-singularity-1d355c.svg?labelColor=000000)](https://sylabs.io/docs/)
[![Launch on Seqera Platform](https://img.shields.io/badge/Launch%20%F0%9F%9A%80-Seqera%20Platform-%234256e7)](https://cloud.seqera.io/launch?pipeline=https://github.com/NBISweden/ameta)

## Introduction

**NBISweden/ameta** is a bioinformatics pipeline for identifying and authenticating microbial sequences in ancient DNA shotgun metagenomics samples. It is a [Nextflow](https://www.nextflow.io)/nf-core reimplementation of the original Snakemake workflow [NBISweden/aMeta](https://github.com/NBISweden/aMeta), described in Pochon, Bergfeldt et al., *Genome Biology* 2023 ([doi:10.1186/s13059-023-03083-9](https://doi.org/10.1186/s13059-023-03083-9)).

Starting from shotgun sequencing reads, the pipeline:

1. Trims adapters and filters short reads with [Cutadapt](https://cutadapt.readthedocs.io/), with QC before and after trimming via [FastQC](https://www.bioinformatics.babraham.ac.uk/projects/fastqc/) and [MultiQC](http://multiqc.info/)
2. Performs k-mer-based taxonomic classification with [KrakenUniq](https://github.com/fbreitwieser/krakenuniq) and screens for common microbial pathogens
3. Aligns reads with [Bowtie2](https://bowtie-bio.sourceforge.net/bowtie2/) and profiles deamination patterns with [mapDamage2](https://ginolhac.github.io/mapDamage/)
4. Performs Lowest Common Ancestor (LCA) alignment with [MALT](https://software-ab.cs.uni-tuebingen.de/download/malt/)
5. Authenticates and validates candidate ancient microbial species with [MaltExtract](https://github.com/rhuebler/HOPS)

Each of these analysis stages beyond the initial QC/classification (MapDamage2, the full MALT/authentication pipeline, and Krona taxonomy plots) can be individually toggled on or off. The output includes per-sample, per-species authentication scores and diagnostic plots (deamination profile, coverage evenness, read length distribution, PMD scores, and more), alongside abundance matrices from both KrakenUniq and MALT.

## Usage

> [!NOTE]
> If you are new to Nextflow and nf-core, please refer to [this page](https://nf-co.re/docs/get_started/environment_setup/overview) on how to set-up Nextflow. Make sure to [test your setup](https://nf-co.re/docs/get_started/run-your-first-pipeline) with `-profile test` before running the workflow on actual data.

<!-- TODO nf-core: Describe the minimum required steps to execute the pipeline, e.g. how to prepare samplesheets.
     Explain what rows and columns represent. For instance (please edit as appropriate):

First, prepare a samplesheet with your input data that looks as follows:

`samplesheet.csv`:

```csv
sample,fastq_1,fastq_2
CONTROL_REP1,AEG588A1_S1_L002_R1_001.fastq.gz,AEG588A1_S1_L002_R2_001.fastq.gz
```

Each row represents a fastq file (single-end) or a pair of fastq files (paired end).

-->

Now, you can run the pipeline using:

<!-- TODO nf-core: update the following command to include all required parameters for a minimal example -->

```bash
nextflow run NBISweden/ameta \
   -profile <docker/singularity/.../institute> \
   --input samplesheet.csv \
   --outdir <OUTDIR>
```

> [!WARNING]
> Please provide pipeline parameters via the CLI or Nextflow `-params-file` option. Custom config files including those provided by the `-c` Nextflow option can be used to provide any configuration _**except for parameters**_; see [docs](https://nf-co.re/docs/running/run-pipelines#using-parameter-files).

## Credits

NBISweden/ameta was originally written by Mahesh Binzer-Panchal.

We thank the following people for their extensive assistance in the development of this pipeline:

<!-- TODO nf-core: If applicable, make list of people who have also contributed -->

## Contributions and Support

If you would like to contribute to this pipeline, please see the [contributing guidelines](docs/CONTRIBUTING.md).

## Citations

<!-- TODO nf-core: Add citation for pipeline after first release. Uncomment lines below and update Zenodo doi and badge at the top of this file. -->
<!-- If you use NBISweden/ameta for your analysis, please cite it using the following doi: [10.5281/zenodo.XXXXXX](https://doi.org/10.5281/zenodo.XXXXXX) -->

<!-- TODO nf-core: Add bibliography of tools and data used in your pipeline -->

An extensive list of references for the tools used by the pipeline can be found in the [`CITATIONS.md`](CITATIONS.md) file.

This pipeline uses code and infrastructure developed and maintained by the [nf-core](https://nf-co.re) community, reused here under the [MIT license](https://github.com/nf-core/tools/blob/main/LICENSE).

> **The nf-core framework for community-curated bioinformatics pipelines.**
>
> Philip Ewels, Alexander Peltzer, Sven Fillinger, Harshil Patel, Johannes Alneberg, Andreas Wilm, Maxime Ulysse Garcia, Paolo Di Tommaso & Sven Nahnsen.
>
> _Nat Biotechnol._ 2020 Feb 13. doi: [10.1038/s41587-020-0439-x](https://dx.doi.org/10.1038/s41587-020-0439-x).

# nf-core-aMeta: faithfulness to the Snakemake original

The nf-core Nextflow pipeline is a scientifically faithful reproduction of Snakemake aMeta.
All tool choices, databases, filtering thresholds, and analytical flags match the original.
This document records where the two pipelines look different and why the outputs are equivalent.

---

## Implementation differences (equivalent outputs)

Different code, same scientific result.

| # | What differs | Snakemake approach | Nextflow approach | Why equivalent |
|---|---|---|---|---|
| 1 | Bowtie2 SAM header dedup | Three-step grep/cat pipeline: extract headers with an **unanchored** `grep @`, extract reads, concatenate with deduped headers (`awk '!seen[$2]++'`) | Inline awk stage in the bowtie2→samtools pipe, **anchored**: `awk '/^@/{ if (!seen[$2]++) print; next }{ print }'` | For the intended purpose (deduping repeated `@SQ` lines from a multi-reference index) both give the same result. **Not a strict equivalence, however**: Snakemake's unanchored `grep @` also matches alignment/data lines that happen to contain a literal `@` character (e.g. a Phred+33 quality score of 31). Confirmed via a synthetic-SAM test that this duplicates such reads in the *Snakemake* output only. The Nextflow patch is anchored and does not have this bug — it is more correct than the original, not merely identical. Scientific impact is negligible (affects at most a handful of reads with that specific quality value per run) but the "outputs identical" framing from the original audit was overbroad. Patch recorded in `modules/nf-core/bowtie2/align/bowtie2-align.diff`. |
| 2 | MALT `-a2t` flag | Runtime version detection: `-a2taxonomy` for MALT ≤ 0.4, `-a2t` for ≥ 0.5 | Hardcoded `"a2t"` | The pipeline pins container `malt:0.62` (≥ 0.5). The hardcoded flag is correct for that container. |
| 3 | NCBI taxonomy files for MaltExtract | Explicit download rules fetch `ncbi.map` and `ncbi.tre` before MaltExtract runs | MaltExtract auto-fetches on first run when `params.ncbi_dir` is empty; offline users pre-populate the directory | Online users: identical result. Offline users: equivalent (supply the same files). |
| 4 | MALT alignment output naming | Output path explicitly ends `.sam.gz` | Output path ends `.sam` | MALT always writes gzip-compressed SAM regardless of the filename extension. Both produce `{sample}.trimmed.sam.gz`. |
| 5 | FastQC memory | `--memory {mem_mb}` passed as a FastQC flag derived from the rule's `mem_mb` resource | No `--memory` flag; memory controlled via the Nextflow process `memory` directive | Both prevent out-of-memory failures. The Nextflow process directive achieves the same at the scheduler level. |
| 6 | MALT build/run tool version | Single conda env (`envs/malt.yaml`) guarantees `malt-build` and `malt-run` are the same version | `MALT_BUILD` pins container `malt:0.6.2`; `MALT_RUN` pins `malt:0.6.1` | Both are ≥ 0.5 so the `-a2t` flag (row 2) stays correct either way, and the RMA6 format is stable across this patch bump. A real, previously unflagged inconsistency worth tracking if either module is updated independently in future. |
| 7 | MALT_PREPAREDB sequence extraction | `grep -Ff seqids.project $nt_fasta \| sed 's/>//g' > project.headers`, then `seqtk subseq $nt_fasta project.headers`: a full linear scan of the entire nt_fasta body (headers *and* sequence lines) to build a header list, before extracting | `samtools faidx $nt_fasta -r seqids.project`: looks up each wanted sequence ID directly in the FASTA's existing `.fai` index, no `project.headers` intermediate | Same seqid list (`seqids.project`) in both; `seqtk subseq` only ever matched on the first whitespace-delimited token of each name line anyway, so the full header/description text `grep` produced was never functionally required. Same sequences extracted either way. Changed because on the real ~373GB NT `library.fna`, the Snakemake-style full-file `grep` took multiple days (observed: still incomplete after 6 days on a real run) for a taxon set the indexed `samtools faidx` lookup resolves in a lookup. Snakemake side intentionally left unchanged. |
| 8 | Authentication skip logic for invalid ref IDs | `_aggregate_utils()`/`get_ref_id()` (`common.smk`) run in Snakemake's driver process at DAG-resolution time; taxids where MaltExtract's readDist output is missing or degenerates to the taxid itself are never requested, so `Breadth_Of_Coverage`, `PMD_scores`, `Deamination`, `Authentication_Score`, and `Post_Processing` are never invoked for them | `MALTEXTRACT` (patched via `maltextract.diff`) emits an optional `ref_id` output computed with the same logic; `workflows/ameta.nf` joins `.out.results` against `.out.ref_id` to build `ch_maltextract_valid`, which every downstream authentication step consumes instead of `MALTEXTRACT.out.results` directly | Same exclusion predicate evaluated per (sample, taxid) either way. Snakemake decides at DAG-resolution time in its driver process, so excluded rules are never scheduled; Nextflow's dataflow model has no equivalent lazy scheduling, so `MALTEXTRACT` itself still always runs (matching Snakemake, where `Malt_Extract` isn't gated either), but the channel join prevents every step downstream of it from launching for excluded pairs, matching which files exist at the end. Fixes a previously-unflagged gap where `BREADTHOFCOVERAGE` would either crash (pipefail on a zero-match `grep`) or produce spurious output for these pairs, and `POSTPROCESSINGAMPS` ran unconditionally where Snakemake would have skipped it. |
| 9 | KrakenUniq `--fastq-input` flag | `krakenuniq --preload --db {DB} --fastq-input {fastq} --threads {threads} --output {seqs} --report-file {report} --gzip-compressed --only-classified-out` (`krakenuniq.smk:22`) | `KRAKENUNIQ_PRELOADEDKRAKENUNIQ`'s `ext.args2` sets only `--gzip-compressed --only-classified-out`; `--fastq-input` is never passed | Verified against the actual `krakenuniq` wrapper script (`fbreitwieser/krakenuniq/scripts/krakenuniq`): `--fasta-input`/`--fastq-input`/`--gzip-compressed`/`--bzip2-compressed` are accepted only for backward compatibility — the parsed values are used solely to print a deprecation notice ("No need to use --fasta-input or --fastq-input anymore, format is detected automatically") and have no effect on classification behaviour. Format and compression are always auto-detected regardless of whether these flags are passed. No behavioural difference; not something that needs fixing. |
| 10 | Krona taxonomy DB provisioning | CI runs `updateTaxonomy.sh` as a separate step before the pipeline; `KrakenUniq2Krona`'s rule only passes `--tax` to `ktImportTaxonomy` if `config['krona_db']` is already set, otherwise relies on an external DB already present on disk | `workflows/ameta.nf` runs `KRONA_KTUPDATETAXONOMY` inline as part of the pipeline's own DAG unless `params.krona_taxonomy_file` is supplied | Scientifically equivalent either way — same taxonomy DB either way, only its provisioning differs. Adds a one-time network dependency to a default Nextflow run that Snakemake's default path doesn't have. Same category as row 3 (MaltExtract NCBI taxonomy auto-fetch). Logged for awareness, not something to revert. |
| 11 | `MAKENODELIST` granularity | `Make_Node_List` invoked once per `(sample, taxid)` via Snakemake's per-directory wildcards; no `localrules` entry, so it's submitted to the cluster like any other rule (throttled by the profile's `max-jobs-per-second: 1`) | `MAKENODELIST` invoked once per **sample**, looking up all of that sample's candidate taxids in a single awk pass over the taxDB, then split back into individual `<taxid>.node_list.txt` files at the channel level before reaching `MALTEXTRACT` | The Nextflow module previously carried a hardcoded `executor 'local'` (inherited verbatim from an earlier Nextflow prototype, not present — and not implied — in the Snakemake original). At per-taxid granularity on a full dataset this fanned out into hundreds-to-thousands of real OS processes forced onto the Nextflow head node regardless of `-profile`, exhausting the host's process limit. Batching drops per-run process count from O(samples × candidate taxa) to O(samples); `MALTEXTRACT` and every downstream authentication step still receive exactly one file per `(sample, taxid)`, unchanged. |
| 12 | KrakenUniq `--preload-size` chunked DB loading | `krakenuniq.smk` passes a configurable `--preload-size`, genuinely bounding resident DB memory during classification instead of loading the whole DB (added aMeta v1.2.0, PR #211) | `KRAKENUNIQ_PRELOADEDKRAKENUNIQ`'s script checked `task.ext.args` for `--preload-size` only to decide whether to skip the separate full-`--preload` step, but never passed `${args}` into the actual per-sample `krakenuniq` invocation — setting `--preload-size` silently disabled preloading with no bounded-cache substitute (2026-09-09) | Verified with a standalone `nextflow run` of the module in isolation: the rendered `.command.sh` showed `--preload-size` absent from the real classify command. Confirmed byte-identical on `nf-core/modules` `master` — an upstream bug, not a stale vendored copy. Patched via `modules/nf-core/krakenuniq/preloadedkrakenuniq/krakenuniq-preloadedkrakenuniq.diff` (proper `nf-core modules patch`, recorded in `modules.json`) to thread `${args}` through in both script branches and both single/paired-end cases. `--preload-size` vs `--preload` producing equivalent classification results was already confirmed by the KrakenUniq developers per aMeta PR #211. |

---

## Intentional design decisions

Places where Nextflow deliberately differs from Snakemake to follow nf-core conventions. No scientific outputs are affected.

| # | What differs | Snakemake | Nextflow | Reason |
|---|---|---|---|---|
| 1 | Default `publishDir` base path | Hardcoded `results/` | `params.outdir` (default `results/`) | nf-core convention for configurable output paths |
| 2 | Sample include/exclude filtering | `config["samples"]["include"/"exclude"]` filter the sample list before any rules run | Not implemented as parameters | nf-core convention: users control sample selection by editing the samplesheet directly |
| 3 | Software version reporting | Conda environment files pin tool versions per rule; `snakemake --report` can generate an HTML report including environment details | Every process emits tool versions at runtime; collected into `software_versions.yml` and shown in MultiQC | Both pipelines record tool versions. The nf-core approach collects them at runtime per process execution rather than from static environment definitions. |

---

## Known output differences (scientifically equivalent)

These files have different md5 checksums between the two pipelines but contain the same scientific content.

| Output | Reason for difference |
|--------|----------------------|
| `malt_abundance_matrix_rma6.txt` | `rma-tabuliser` reads the non-deterministic RMA6 binary files; the underlying count data is the same but row/column ordering may differ depending on MEGAN version (`rma2info` 6.12.3 in Snakemake vs 6.21.7 in Nextflow container). Verified non-empty; Snakemake used MEGAN 6.12.3 with mawk; Nextflow uses MEGAN 6.21.7 container + gawk. |
| `malt_abundance_matrix_sam.txt` | Per-sample `sam_counts.txt` files are byte-identical between pipelines. The combined matrix differs only in column headers: Nextflow stages files as `bar.sam_counts.txt` → column name becomes `bar.txt` after `gsub(".sam_counts", "")`, whereas Snakemake uses per-sample subdirectories with files named `sam_counts.txt`. Count values are the same. |
| `krakenuniq_abundance_matrix.txt` | Same cause as above. Per-sample filtered KrakenUniq reports are byte-identical. Column headers in the matrix reflect the staged filenames: `bar.krakenuniq.report.txt.filtered` in Nextflow vs Snakemake's naming convention. Species names, taxids, and read counts are the same. |
| MALT RMA6 files (`*.trimmed.rma6`) | Non-deterministic parallel hash-table construction in `malt-build`; `table0.db` and `table0.idx` differ. Downstream MaltExtract outputs from both pipelines are byte-identical, confirming the scientific content is the same. |
| Authentication plots (PDFs, PNGs) | Floating-point rendering differences downstream of the non-deterministic RMA6 files. |
| MapDamage outputs | MCMC is stochastic; values differ run-to-run but scientific conclusions are the same. |
| Raw `KRAKENUNIQ_PRELOADEDKRAKENUNIQ` output folder name | `KRAKENUNIQ_PRELOADEDKRAKENUNIQ` batches all samples of one datatype (single/paired-end) into a single process call (see "KrakenUniq batching" below), so its own `publishDir` writes under a synthetic batch id (`KRAKENUNIQ/krakenuniq_single_end/...`) rather than per-sample. Downstream `KRAKENUNIQ_FILTER`/`KRAKENUNIQ_TOKRONA` correctly re-key to the real per-sample meta and publish the filtered/actionable outputs under `KRAKENUNIQ/{sample}/` as before — only the raw, pre-filter report/classified-assignment files land in the batch-named folder. Content is identical, only the raw-file location differs. |

### KrakenUniq batching (audited, no bug found)

`KRAKENUNIQ_PRELOADEDKRAKENUNIQ` was rewritten to batch every sample of the same datatype into one process call, so the (very large) database is preloaded once per datatype rather than once per sample — a performance change with no intended scientific effect. This was independently audited end-to-end and confirmed correct:
- meta/reads pairing survives `groupTuple`/`flatten()` — list indices stay aligned because both lists originate from the same upstream emission per sample.
- The batched `report`/`classified_assignment` outputs are re-keyed back to their originating per-sample `meta` by an **exact match** on the sample id embedded in each output filename (the module's `PREFIX` is literally `meta.id`) — not a fuzzy or substring match, so same-batch samples cannot cross-wire even with adversarial sample-id naming.
- The single-file-vs-`List` Nextflow arity edge case (a batch of exactly one sample) is explicitly guarded (`reports instanceof List ? reports : [reports]`).

---

## Authentication of absent taxa (foo/42862)

In the Snakemake results directory, `AUTHENTICATION/foo/42862/` exists with MaltExtract outputs but no downstream files (no `breadth_of_coverage`, `sorted.bam`, `PMDscores.txt`, `authentication_scores.txt`, or HOPS heatmaps). Nextflow produces no output for taxid 42862 for sample foo.

**Root cause:** The Snakemake results directory is a mix of outputs from multiple runs. The foo/42862 tree is a leftover from an earlier run where foo's `krakenuniq.output.filtered` included taxid 42862. In the run whose outputs were compared, `krakenuniq.output.filtered` for foo is byte-identical between both pipelines (`ca03165494170f2f7d8c91830a14ed92`) and contains only taxid 632. Nextflow's behaviour is correct.

**Why downstream steps did not run in Snakemake for 42862:** `Make_Node_List` produced an empty `node_list.txt` because taxid 42862 is absent from the KrakenUniq taxDB. `Malt_Extract` therefore ran with an empty node list and did not produce `default/readDist/*_additionalNodeEntries.txt`, which is the required input for `Breadth_Of_Coverage`. Snakemake could not schedule any further downstream rules. There is no explicit guard; the data dependency chain naturally stalled.

---

## Resource provisioning corrections (2026-07-31 audit)

`conf/base.config` still carried its unmodified nf-core template defaults (`process_single/low/medium/high` labels) for every process except `MALTEXTRACT`. Comparing against Snakemake's `threads:` declarations and the pipeline authors' own reference cluster profile (`aMeta/profile/config.yaml`) found several processes significantly over- or under-provisioned. Fixed directly in `conf/modules.config` (hardcoded per-process overrides, not new pipeline parameters — users needing different values override via a custom config with `-c`):

| Process | Was | Now | Basis |
|---|---|---|---|
| `CUTADAPT` | 6 cpu / 36GB (`process_medium`) | `cpus=1`, `memory=4.GB` | Snakemake runs cutadapt single-threaded |
| `BOWTIE2_BUILD` | 12 cpu (`process_high`) | `cpus=4` | Snakemake builds the index single-threaded (deliberately — indexing parallelizes poorly) |
| `KRAKENUNIQ_PRELOADEDKRAKENUNIQ` | 12 cpu / 72GB (`process_high`) | `cpus=10`, `memory=200.GB * attempt` | Matches Snakemake's thread count; `--preload` loads the full DB into RAM and real aDNA databases exceed 72GB |
| `MAPDAMAGE2` | 1 cpu / 6GB / 4h (`process_single`) | `memory=8.GB * attempt`, `time=20.h * attempt` | MCMC fitting on real BAMs risks timing out at the 4h default (cpu unchanged — the tool doesn't multithread regardless of Snakemake's defensive `threads: 10`) |
| `MALT_BUILD` | 12 cpu / 72GB (`process_high`) | `cpus=20`, `memory=200.GB * attempt` | Matches Snakemake's thread count |
| `MALT_RUN` | 12 cpu / 72GB / 16h (`process_high`) | `cpus=20`, `memory=512.GB * attempt`, `time=80.h * attempt` | Matches the pipeline authors' own documented production requirement (`profile/config.yaml` `set-resources: Malt:mem_mb=512000, runtime=4800`) — previously 7× under on memory, 5× under on time |
| `MALTEXTRACT` | flat `32.GB` | `32.GB * attempt` | Same default (matches Snakemake's `-Xmx32G`), now scales on retry |

`conf/test.config`'s existing `resourceLimits` (4 cpu / 15GB / 1h) automatically clamps all of the above during `-profile test`, so no separate test-profile caps were needed. Verified via `pixi run stub` (39/39 tasks completed).

## Known limitation: paired-end Cutadapt trimming

The Snakemake original only supports single-end input. Nextflow's samplesheet adds real paired-end auto-detection (`assets/schema_input.json`), which is new capability, not a deviation from the original — but `conf/modules.config`'s `CUTADAPT` `ext.args` only ever sets `-a` (never `-A` for read 2). If paired-end input is actually used in production, read 2 would not get its adapter trimmed. Does not affect fidelity to the Snakemake original (which never exercises this path). Flagged here as follow-up work, not yet fixed.

---

## Verified-correct implementations

The following were inspected and confirmed identical in behaviour despite looking different.

| Stage | Detail |
|-------|--------|
| Cutadapt adapters | Same sequences (`AGATCGGAAGAG` illumina default, nextera opt-in, custom list); same `--minimum-length 31`; same conditional logic via `params.adapters_illumina/nextera/custom` |
| KrakenUniq filter | Same script (`filter_krakenuniq.py`), same defaults (`n_unique_kmers=1000`, `n_tax_reads=200`, rank `species`) |
| KrakenUniq → Krona | Same script (`krakenuniq2krona.py`) + `cut -f 2,3` + `ktImportTaxonomy` |
| SAMTOOLS_VIEW seqid filtering | Snakemake: `xargs samtools view` with a `.seq_ids` file. Nextflow: `ext.args2 = { meta.seqids.join(' ') }` passes the same IDs as positional region arguments. |
| MALT flags | All flags identical: `SemiGlobal`, `BlastN`, `minSupport 1`, `maxAlignmentsPerQuery 100`, `topPercent 1`, `minPercentIdentityLCA/minPercentIdentity 85.0`; `-v` hardcoded in nf-core module |
| MaltExtract flags | All flags match: `def_anc`, `--reads`, `--matches`, `--minPI 85.0`, `--maxReadLength 0`, `--minComp 0.0`, `--meganSummary`, `--verbose`, `--destackingOff`, `--downSampOff`, `--dupRemOff` |
| MaltExtract memory | Snakemake: `-Xmx32G` in shell command. Nextflow: `memory = 32.GB` process directive. Same allocation. |
| MapDamage2 MCMC fitting | Both run MCMC fitting by default (`--merge-reference-sequences`, no `--no-stats`) |
| MALT_PREPAREDB logic | Snakemake `scripts/malt-build.py` rewritten as `modules/local/malt/preparedb/main.nf`. No longer identical — see "Implementation differences" row 7: extraction now uses `samtools faidx` against the existing `.fai` index instead of the Snakemake original's full-file `grep`. |
| Authentic.R `$ID` | Snakemake: `{sample}.trimmed.rma6` wildcard. Nextflow: RMA6 basename stripped from `*_editDistance.txt`. Both resolve to the same value. |
| BreadthOfCoverage RefID extraction | Snakemake: `split(";")[1][1:]`. Nextflow: `awk -F';_'`. Both extract the accession from `taxid;_accession` format. |
| PMDtools flags | `--printDS` (score); `--platypus --number 2000000` (deamination) — identical in both |
| Analysis toggles | Snakemake: input functions return `[]` when a toggle is off. Nextflow: `if (params.run_*)` blocks exclude the entire subworkflow from the DAG. |

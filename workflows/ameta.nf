/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT MODULES / SUBWORKFLOWS / FUNCTIONS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

// QC subworkflow
include { FASTQC as FASTQC_RAW        } from '../modules/nf-core/fastqc/main'
include { FASTQC as FASTQC_TRIM       } from '../modules/nf-core/fastqc/main'
include { CUTADAPT                    } from "$projectDir/modules/nf-core/cutadapt/main"

// Align subworkflow
include { BOWTIE2_BUILD       } from "$projectDir/modules/nf-core/bowtie2/build/main"
include { FASTQ_ALIGN_BOWTIE2 } from "$projectDir/subworkflows/nf-core/fastq_align_bowtie2/main"

// Krakenuniq subworkflow
include { KRAKENUNIQ_PRELOADEDKRAKENUNIQ } from "$projectDir/modules/nf-core/krakenuniq/preloadedkrakenuniq/"
include { KRAKENUNIQ_BUILD               } from "$projectDir/modules/nf-core/krakenuniq/build/main"
include { KRAKENUNIQ_FILTER              } from "$projectDir/modules/local/krakenuniq/filter"
include { KRAKENUNIQ_TOKRONA             } from "$projectDir/modules/local/krakenuniq/tokrona"
include { KRONA_KTUPDATETAXONOMY         } from "$projectDir/modules/nf-core/krona/ktupdatetaxonomy/main"
include { KRONA_KTIMPORTTAXONOMY         } from "$projectDir/modules/nf-core/krona/ktimporttaxonomy/main"
include { KRAKENUNIQ_ABUNDANCEMATRIX     } from "$projectDir/modules/local/krakenuniq/abundancematrix"

// Damage subworkflow
include { WRITESEQIDS   } from "$projectDir/modules/local/writeseqids"
include { SAMTOOLS_VIEW } from "$projectDir/modules/nf-core/samtools/view/main"
include { MAPDAMAGE2    } from "$projectDir/modules/nf-core/mapdamage2/main"

// Malt subworkflow
include { MALT_PREPAREDB           } from "$projectDir/modules/local/malt/preparedb"
include { MALT_BUILD               } from "$projectDir/modules/nf-core/malt/build/main"
include { MALT_RUN                 } from "$projectDir/modules/nf-core/malt/run/main"
include { MALT_QUANTIFYABUNDANCE   } from "$projectDir/modules/local/malt/quantifyabundance"
include { MALT_ABUNDANCEMATRIXSAM  } from "$projectDir/modules/local/malt/abundancematrixsam"
include { MALT_ABUNDANCEMATRIXRMA6 } from "$projectDir/modules/local/malt/abundancematrixrma6"

// Authentic subworkflow
include { MAKENODELIST           } from "$projectDir/modules/local/makenodelist"
include { MALTEXTRACT            } from "$projectDir/modules/nf-core/maltextract/main"
include { POSTPROCESSINGAMPS     } from "$projectDir/modules/local/postprocessingamps"
include { SAMTOOLS_FAIDX         } from "$projectDir/modules/nf-core/samtools/faidx/main"
include { BREADTHOFCOVERAGE      } from "$projectDir/modules/local/breadthofcoverage"
include { READLENGTHDISTRIBUTION } from "$projectDir/modules/local/readlengthdistribution"
include { PMDTOOLS_SCORE         } from "$projectDir/modules/local/pmdtools/score"
include { PMDTOOLS_DEAMINATION   } from "$projectDir/modules/local/pmdtools/deamination"
include { AUTHENTICATIONPLOTS    } from "$projectDir/modules/local/authenticationplots"
include { AUTHENTICATIONSCORE    } from "$projectDir/modules/local/authenticationscore"

// summary subworkflow
include { PLOTAUTHENTICATIONSCORE } from "$projectDir/modules/local/plotauthenticationscore"

include { FASTQC                 } from '../modules/nf-core/fastqc/main'
include { MULTIQC                } from '../modules/nf-core/multiqc/main'
include { paramsSummaryMap       } from 'plugin/nf-validation'
include { paramsSummaryMultiqc   } from '../subworkflows/nf-core/utils_nfcore_pipeline'
include { softwareVersionsToYAML } from '../subworkflows/nf-core/utils_nfcore_pipeline'
include { methodsDescriptionText } from '../subworkflows/local/utils_nfcore_ameta_pipeline'

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    RUN MAIN WORKFLOW
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

workflow AMETA {

    take:
    ch_samplesheet // channel: samplesheet read in from --input

    main:

    ch_versions = Channel.empty()
    ch_multiqc_files = Channel.empty()

    //
    // SUBWORKFLOW: QC
    //
    FASTQC_RAW (
        ch_samplesheet
    )
    ch_versions = ch_versions.mix(FASTQC_RAW.out.versions.first())
    CUTADAPT (
        ch_samplesheet
    )
    ch_versions = ch_versions.mix(CUTADAPT.out.versions.first())
    FASTQC_TRIM (
        CUTADAPT.out.reads
    )
    ch_versions = ch_versions.mix(FASTQC_TRIM.out.versions.first())

    //
    // SUBWORKFLOW: ALIGN
    //
    ch_reference = Channel.fromPath( params.bowtie2_db, checkIfExists: true)
        .map{ file -> [ [ id: file.baseName ], file ] }
    BOWTIE2_BUILD( ch_reference )
    ch_versions = ch_versions.mix(BOWTIE2_BUILD.out.versions)
    FASTQ_ALIGN_BOWTIE2(
        CUTADAPT.out.reads,                   // ch_reads
        BOWTIE2_BUILD.out.index.collect(),    // ch_index
        false,                                // save unaligned
        false,                                // sort bam
        ch_reference.collect()                // ch_fasta
    )
    ch_versions = ch_versions.mix(FASTQ_ALIGN_BOWTIE2.out.versions)

    // SUBWORKFLOW: KRAKENUNIQ
    if( !params.krakenuniq_db ) {
        // TODO: Use Krakenuniq_Download to fetch taxonomy
        KRAKENUNIQ_BUILD (
            [   // Form input tuple.
                [ id: 'KrakenUniq_DB' ],
                file( params.krakenuniq_library_dir, checkIfExists: true ),
                file( params.krakenuniq_taxonomy_dir, checkIfExists: true ),
                file( params.krakenuniq_seq2taxid, checkIfExists: true )
            ]
        )
        ch_versions = ch_versions.mix(KRAKENUNIQ_BUILD.out.versions)
    }
    ch_krakenuniq_db = params.krakenuniq_db ?
        Channel.fromPath(params.krakenuniq_db, type: 'dir', checkIfExists: true ).collect() :
        KRAKENUNIQ_BUILD.out.db.collect{ it[1] }
    KRAKENUNIQ_PRELOADEDKRAKENUNIQ(
        CUTADAPT.out.reads,               // [ meta, fastqs ]
        ch_krakenuniq_db,                 // db
        params.krakenuniq_ram_chunk_size, // ram_chunk_size
        true,                             // save_output_reads
        true,                             // report_file
        true                              // save_output
    )
    ch_versions = ch_versions.mix(KRAKENUNIQ_PRELOADEDKRAKENUNIQ.out.versions.first())
    KRAKENUNIQ_FILTER(
        KRAKENUNIQ_PRELOADEDKRAKENUNIQ.out.report,
        params.n_unique_kmers,
        params.n_tax_reads,
        file( params.pathogenomes_found, checkIfExists: true )
    )
    ch_versions = ch_versions.mix(KRAKENUNIQ_FILTER.out.versions.first())
    KRAKENUNIQ_TOKRONA(
        KRAKENUNIQ_FILTER.out.filtered.join(KRAKENUNIQ_PRELOADEDKRAKENUNIQ.out.classified_assignment)
    )
    ch_versions = ch_versions.mix(KRAKENUNIQ_TOKRONA.out.versions.first())
    KRONA_KTUPDATETAXONOMY()
    ch_versions = ch_versions.mix(KRONA_KTUPDATETAXONOMY.out.versions)
    KRONA_KTIMPORTTAXONOMY(
        KRAKENUNIQ_TOKRONA.out.krona,
        params.krona_taxonomy_file ? file( params.krona_taxonomy_file, checkIfExists: true ) : KRONA_KTUPDATETAXONOMY.out.db
    )
    ch_versions = ch_versions.mix(KRONA_KTIMPORTTAXONOMY.out.versions.first())
    KRAKENUNIQ_ABUNDANCEMATRIX(
        KRAKENUNIQ_FILTER.out.filtered.collect{ it[1] },
        params.n_unique_kmers,
        params.n_tax_reads
    )
    ch_versions = ch_versions.mix(KRAKENUNIQ_ABUNDANCEMATRIX.out.versions)

    // SUBWORKFLOW: Map Damage
    Channel.fromPath( params.bowtie2_seqid2taxid_db, checkIfExists: true )
        .flatMap{ tsv -> tsv.splitCsv(header:false, sep:"\t")*.reverse() }
        .groupTuple() // [ taxid, [ ref1, ref2, ref3 ] ]
        .combine( KRAKENUNIQ_FILTER.out.species_tax_id.flatMap{ meta, txt -> txt.splitText().collect{ [ it.trim(), meta ] } }, by: 0 )
        .map { taxid, seqids, meta -> [ meta, taxid, seqids ] }
        .combine( FASTQ_ALIGN_BOWTIE2.out.bam.join(FASTQ_ALIGN_BOWTIE2.out.bai), by: 0 )
        // Add taxid and seqids to meta so samtools view $args2 can reference it
        .map { meta, taxid, seqids, bam, bai -> [ meta + [ taxid: taxid, seqids: seqids ], bam, bai ] }
        .set{ ch_taxid_seqrefs }
    WRITESEQIDS ( ch_taxid_seqrefs )
    SAMTOOLS_VIEW (
        ch_taxid_seqrefs, // bam files
        [ [] , [] ],      // Empty fasta reference
        []                // Empty qname file
    )
    ch_versions = ch_versions.mix(SAMTOOLS_VIEW.out.versions.first())
    MAPDAMAGE2 (
        SAMTOOLS_VIEW.out.bam, // bams
        ch_reference.collect{ it[1] } // fasta
    )
    ch_versions = ch_versions.mix(MAPDAMAGE2.out.versions.first())

    // SUBWORKFLOW: Malt
    MALT_PREPAREDB (
        KRAKENUNIQ_ABUNDANCEMATRIX.out.species_taxid_list,
        file(params.malt_seqid2taxid_db, checkIfExists: true),
        file(params.malt_nt_fasta, checkIfExists: true)
    )
    ch_versions = ch_versions.mix(MALT_PREPAREDB.out.versions)
    MALT_BUILD (
        MALT_PREPAREDB.out.library,
        [],
        file(params.malt_accession2taxid, checkIfExists: true) // Note: Deprecated. Should be replaced with Megan db.
    )
    ch_versions = ch_versions.mix(MALT_BUILD.out.versions)
    MALT_RUN (
        CUTADAPT.out.reads,
        MALT_BUILD.out.index.collect(),
        'BlastN'
    )
    ch_versions = ch_versions.mix(MALT_RUN.out.versions.first())
    MALT_QUANTIFYABUNDANCE (
        MALT_RUN.out.alignments,
        KRAKENUNIQ_ABUNDANCEMATRIX.out.species_taxid_list.collect()
    )
    ch_versions = ch_versions.mix(MALT_QUANTIFYABUNDANCE.out.versions.first())
    MALT_ABUNDANCEMATRIXSAM ( // Note: Implicit merge since two value channels are used
        MALT_QUANTIFYABUNDANCE.out.counts.collect{ it[1] },
        KRAKENUNIQ_ABUNDANCEMATRIX.out.species_names_list
    )
    ch_versions = ch_versions.mix(MALT_ABUNDANCEMATRIXSAM.out.versions)
    MALT_ABUNDANCEMATRIXRMA6 ( MALT_RUN.out.rma6.collect{ it[1] } )
    ch_versions = ch_versions.mix(MALT_ABUNDANCEMATRIXRMA6.out.versions)

    // SUBWORKFLOW: authentic
    // Rule: Create_Sample_TaxID_Directories, however taxid is added to meta data instead
    ch_species_with_taxid = KRAKENUNIQ_FILTER.out.species_tax_id
        .flatMap{ meta, taxids -> taxids.splitCsv(header: false, sep: '\t').collect{ meta + [ taxid: it[0] ] } }
    MAKENODELIST (
        ch_species_with_taxid,
        ch_krakenuniq_db // Contains the taxDB
    )
    MALTEXTRACT (
        MALT_RUN.out.rma6
            .combine(
                MAKENODELIST.out.node_list
                    .map{ meta, node_list -> [ meta.subMap(meta.keySet() - 'taxid'), meta.taxid, node_list ] },
                by: 0
            )
            .multiMap { meta, rma6, taxid, node_list ->
                rma6: [ meta + [taxid: taxid], rma6 ]
                node_list: node_list
            },
        file( params.ncbi_dir, type: 'dir' ) // TODO: Causes Malt Extract to automatically download the database. Not suitable for offline.
    )
    ch_versions = ch_versions.mix(MALTEXTRACT.out.versions.first())
    POSTPROCESSINGAMPS( MAKENODELIST.out.node_list.join(MALTEXTRACT.out.results) )
    ch_versions = ch_versions.mix(POSTPROCESSINGAMPS.out.versions.first())
    SAMTOOLS_FAIDX (
        ch_reference,
        [ [], [] ] // Empty fai
    )
    malt_nt_fasta = ch_reference.join( SAMTOOLS_FAIDX.out.fai )
        .multiMap { meta, fasta, fai ->
            fasta: fasta
            fai  : fai
        }
    ch_alignments_per_taxid = MALT_RUN.out.alignments
        .combine(
            MALTEXTRACT.out.results
                .map{ meta, results -> [ meta.subMap(meta.keySet() - 'taxid'), meta.taxid, results ] },
            by: 0
        )
        .map { meta, aln, taxid, results -> [ meta + [taxid: taxid], aln, results ] }
    BREADTHOFCOVERAGE (
        ch_alignments_per_taxid,
        malt_nt_fasta.fasta.collect(),
        malt_nt_fasta.fai.collect(),
    )
    ch_versions = ch_versions.mix(BREADTHOFCOVERAGE.out.versions.first())
    READLENGTHDISTRIBUTION ( BREADTHOFCOVERAGE.out.sorted_bam )
    ch_versions = ch_versions.mix(READLENGTHDISTRIBUTION.out.versions.first())
    PMDTOOLS_SCORE ( BREADTHOFCOVERAGE.out.sorted_bam )
    ch_versions = ch_versions.mix(PMDTOOLS_SCORE.out.versions.first())
    PMDTOOLS_DEAMINATION ( BREADTHOFCOVERAGE.out.sorted_bam )
    ch_versions = ch_versions.mix(PMDTOOLS_DEAMINATION.out.versions.first())
    AUTHENTICATIONPLOTS (
        MAKENODELIST.out.node_list
            .join( READLENGTHDISTRIBUTION.out.read_length )
            .join( PMDTOOLS_SCORE.out.pmd_scores )
            .join( BREADTHOFCOVERAGE.out.breadth_of_coverage )
            .join( BREADTHOFCOVERAGE.out.name_list )
            .join( MALTEXTRACT.out.results )
    )
    ch_versions = ch_versions.mix(AUTHENTICATIONPLOTS.out.versions.first())
    ch_authentication_score = MALT_RUN.out.rma6
        .combine(
            MALTEXTRACT.out.results
                .join(BREADTHOFCOVERAGE.out.name_list)
                .join(MAKENODELIST.out.node_list)
                .map{ meta, maltex_dir, name_list, node_list -> [ meta.subMap(meta.keySet()-['taxid']), meta.taxid, maltex_dir, name_list, node_list ] },
            by: 0
        )
        .map { meta, rma6, taxid, maltex_dir, name_list, node_list ->
            [ meta + [ taxid: taxid ], rma6, maltex_dir, name_list, node_list ]
        }
    AUTHENTICATIONSCORE(
        ch_authentication_score
    )
    ch_versions = ch_versions.mix( AUTHENTICATIONSCORE.out.versions.first() )

    // SUBWORKFLOW: summary
    PLOTAUTHENTICATIONSCORE( AUTHENTICATIONSCORE.out.authentication_scores.collect{ it[1] } )
    ch_versions = ch_versions.mix(PLOTAUTHENTICATIONSCORE.out.versions)

    //
    // Collate and save software versions
    //
    softwareVersionsToYAML(ch_versions)
        .collectFile(
            storeDir: "${params.outdir}/pipeline_info",
            name: 'nf_core_pipeline_software_mqc_versions.yml',
            sort: true,
            newLine: true
        ).set { ch_collated_versions }

    //
    // MODULE: MultiQC
    //
    ch_multiqc_config        = Channel.fromPath(
        "$projectDir/assets/multiqc_config.yml", checkIfExists: true)
    ch_multiqc_custom_config = params.multiqc_config ?
        Channel.fromPath(params.multiqc_config, checkIfExists: true) :
        Channel.empty()
    ch_multiqc_logo          = params.multiqc_logo ?
        Channel.fromPath(params.multiqc_logo, checkIfExists: true) :
        Channel.empty()

    summary_params      = paramsSummaryMap(
        workflow, parameters_schema: "nextflow_schema.json")
    ch_workflow_summary = Channel.value(paramsSummaryMultiqc(summary_params))

    ch_multiqc_custom_methods_description = params.multiqc_methods_description ?
        file(params.multiqc_methods_description, checkIfExists: true) :
        file("$projectDir/assets/methods_description_template.yml", checkIfExists: true)
    ch_methods_description                = Channel.value(
        methodsDescriptionText(ch_multiqc_custom_methods_description))

    ch_multiqc_files = ch_multiqc_files.mix(
        ch_workflow_summary.collectFile(name: 'workflow_summary_mqc.yaml'))
    ch_multiqc_files = ch_multiqc_files.mix(ch_collated_versions)
    ch_multiqc_files = ch_multiqc_files.mix(
        ch_methods_description.collectFile(
            name: 'methods_description_mqc.yaml',
            sort: true
        )
    )

    MULTIQC (
        ch_multiqc_files.collect(),
        ch_multiqc_config.toList(),
        ch_multiqc_custom_config.toList(),
        ch_multiqc_logo.toList()
    )

    emit:
    multiqc_report = MULTIQC.out.report.toList() // channel: /path/to/multiqc_report.html
    versions       = ch_versions                 // channel: [ path(versions.yml) ]
}

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    THE END
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

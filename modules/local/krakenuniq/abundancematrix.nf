process KRAKENUNIQ_ABUNDANCEMATRIX {
    label 'process_single'

    // https://github.com/nf-core/atacseq/blob/1a1dbe52ffbd82256c941a032b0e22abbd925b8a/modules/local/deseq2_qc.nf#L7
    // (Bio)conda packages have intentionally not been pinned to a specific version
    // This was to avoid the pipeline failing due to package conflicts whilst creating the environment when using -profile conda
    conda "conda-forge::r-base bioconda::bioconductor-deseq2 bioconda::bioconductor-biocparallel bioconda::bioconductor-tximport bioconda::bioconductor-complexheatmap conda-forge::r-optparse conda-forge::r-ggplot2 conda-forge::r-rcolorbrewer conda-forge::r-pheatmap"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/mulled-v2-8849acf39a43cdd6c839a369a74c0adc823e2f91:ab110436faf952a33575c64dd74615a84011450b-0' :
        'biocontainers/mulled-v2-8849acf39a43cdd6c839a369a74c0adc823e2f91:ab110436faf952a33575c64dd74615a84011450b-0' }"

    input:
    path reports, stageAs:'krakenuniq/*'
    val n_unique_kmers
    val n_tax_reads

    output:
    path("krakenuniq_abundance_matrix"), emit: krakenuniq_abundance_matrix
    path("*.abundance_matrix.log")     , emit: log
    path "versions.yml"                , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "krakenuniq"
    """
    krakenuniq_abundance_matrix.R \\
        krakenuniq \\
        krakenuniq_abundance_matrix \\
        $n_unique_kmers \\
        $n_tax_reads \\
        |& tee ${prefix}.abundance_matrix.log
    plot_krakenuniq_abundance_matrix.R \\
        krakenuniq_abundance_matrix \\
        krakenuniq_abundance_matrix \\
        |& tee -a ${prefix}.abundance_matrix.log

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        r-base: \$(R --version |& sed 's/^.*R version //; s/ .*\$//')
        pheatmap: \$(Rscript -e "library(pheatmap); cat(as.character(packageVersion('pheatmap')))")
    END_VERSIONS
    """

    stub:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    touch ${prefix}.bam

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        r-base: \$(R --version |& sed 's/^.*R version //; s/ .*\$//')
        pheatmap: \$(Rscript -e "library(pheatmap); cat(as.character(packageVersion('pheatmap')))")
    END_VERSIONS
    """
}

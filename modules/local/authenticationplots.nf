process AUTHENTICATIONPLOTS {
    tag "$meta.id"
    label 'process_single'

    // Using same env as krakenuniq/abundancematrix
    conda "conda-forge::r-base bioconda::bioconductor-deseq2 bioconda::bioconductor-biocparallel bioconda::bioconductor-tximport bioconda::bioconductor-complexheatmap conda-forge::r-optparse conda-forge::r-ggplot2 conda-forge::r-rcolorbrewer conda-forge::r-pheatmap"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/mulled-v2-8849acf39a43cdd6c839a369a74c0adc823e2f91:ab110436faf952a33575c64dd74615a84011450b-0' :
        'biocontainers/mulled-v2-8849acf39a43cdd6c839a369a74c0adc823e2f91:ab110436faf952a33575c64dd74615a84011450b-0' }"

    input:
    tuple(
        val(meta),
        path(node_list, stageAs: 'infiles/*'),
        path(read_length, stageAs: 'infiles/*'),
        path(pmd_scores, stageAs: 'infiles/*'),
        path(breadth_of_coverage, stageAs: 'infiles/*')
    )

    output:
    tuple val(meta), path("*.bam"), emit: bam
    path "versions.yml"           , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    authentic.R ${meta.taxid} ${meta.id}.trimmed.rma6 infiles/

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        authenticationplots: \$(samtools --version |& sed '1!d ; s/samtools //')
    END_VERSIONS
    """
}

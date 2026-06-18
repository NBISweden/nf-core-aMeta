process MALT_ABUNDANCEMATRIXRMA6 {
    label 'process_single'

    conda "bioconda::megan:6.24.20 conda-forge::gawk=5.4.0"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://community-cr-prod.seqera.io/docker/registry/v2/blobs/sha256/95/953a61c6c2c46e8aa8619a2ab1f1a2c44ef5f8bbe6607795d8fbc930d80d2cde/data':
        'community.wave.seqera.io/library/megan_gawk:0908b51d47d26819' }"

    input:
    path rma6, stageAs: 'rma6s/*'

    output:
    path "malt_abundance_matrix_rma6.txt", emit: abundance_matrix_rma6
    tuple val("${task.process}"), val('rma-tabuliser'), eval("rma-tabuliser -v"), topic: versions, emit: versions_rma_tabuliser
    tuple val("${task.process}"), val('megan'), eval("rma2info -h |& sed '/version/!d; s/.*version //; s/, .*//'"), topic: versions, emit: versions_megan

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    """
    rma-tabuliser -d rma6s/ $args
    mv rma6s/count_table.tsv malt_abundance_matrix_rma6.txt
    """

    stub:
    """
    touch malt_abundance_matrix_rma6.txt
    """
}

process MALT_ABUNDANCEMATRIXRMA6 {
    label 'process_single'

    conda "bioconda::megan:6.24.20"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/megan:6.24.20--h9ee0642_0':
        'biocontainers/megan:6.24.20--h9ee0642_0' }"

    input:
    path rma6, stageAs: 'rma6s/*'

    output:
    path "malt_abundance_matrix_rma6.txt", emit: abundance_matrix_rma6
    tuple val("${task.process}"), val('rma-tabuliser'), eval("rma-tabuliser -h | sed '/VERSION/{N;N;s/.*\\n    //;q};d'"), topic: versions, emit: versions_rma_tabuliser

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

process AUTHENTICATIONSCORE {
    tag "$meta.id"
    label 'process_single'

    conda "bioconda::hops:0.35"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/hops:0.35--hdfd78af_1' :
        'biocontainers/hops:0.35--hdfd78af_1' }"

    input:
    tuple ( val(meta), path(rma6), path(malt_extract_dir), path(name_list), path(node_list, stageAs: 'node_list.txt'), path(pmd_scores), path(breadth_of_coverage, stageAs: 'breadth_of_coverage'), path(read_length, stageAs: 'read_length.txt') )

    output:
    tuple val(meta), path("*.authentication_scores.txt"), emit: authentication_scores
    tuple val("${task.process}"), val('r-base'), eval("R --version |& sed '1!d; s/R version //; s/ .*//'"), topic: versions, emit: versions_rbase

    when:
    task.ext.when == null || task.ext.when

    script:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    score.R \\
        $rma6 \\
        $malt_extract_dir \\
        $name_list \\
        . \\
        $pmd_scores
    mv authentication_scores.txt ${prefix}.authentication_scores.txt
    """

    stub:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    touch ${prefix}.authentication_scores.txt
    """
}

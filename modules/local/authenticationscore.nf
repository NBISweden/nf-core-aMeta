process AUTHENTICATIONSCORE {
    tag "$meta.id"
    label 'process_single'

    conda "bioconda::hops:0.35"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/hops:0.35--hdfd78af_1' :
        'biocontainers/hops:0.35--hdfd78af_1' }"

    input:
    tuple ( val(meta), path(rma6), path(malt_extract_dir), path(name_list), path(node_list, stageAs: 'node_list.txt') )

    output:
    tuple val(meta), path("*.authentication_scores.txt"), emit: authentication_scores
    path "versions.yml"                                 , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    score.R $rma6 \\
        $malt_extract_dir \\
        $name_list \\
        .
    mv authentication_scores.txt ${prefix}.authentication_scores.txt

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        r-base: \$(R --version |& sed '1!d; s/R version //; s/ .*//')
    END_VERSIONS
    """
}

process MAKENODELIST {
    tag "$meta.id"
    label 'process_single'
    executor 'local'

    conda "conda-forge::gawk=5.3.0"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/gawk:5.3.0' :
        'biocontainers/gawk:5.3.0' }"

    input:
    val meta
    path taxdb_dir

    output:
    tuple val(meta), path("node_list.txt"), emit: node_list
    tuple val("${task.process}"), val('gawk'), eval("awk -Wversion | sed '1!d; s/.*Awk //; s/,.*//'"), topic: versions, emit: versions_gawk

    when:
    task.ext.when == null || task.ext.when

    script:
    """
    awk -F'\\t' '\$1 == "${meta.taxid}" { print \$3 }' ${taxdb_dir}/taxDB > node_list.txt
    """
}

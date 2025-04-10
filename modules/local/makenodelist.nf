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
    path "versions.yml"                   , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    """
    awk '\$1 == "${meta.tax_id}" { print \$3 }' ${taxdb_dir}/taxDB > node_list.txt

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        gawk: \$(awk -Wversion | sed '1!d; s/.*Awk //; s/,.*//')
    END_VERSIONS
    """
}

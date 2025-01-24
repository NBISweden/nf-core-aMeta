process MAKENODELIST {
    tag "$meta.id"
    label 'process_single'
    executor 'local'

    input:
    val meta
    path taxdb_dir

    output:
    tuple val(meta), path("node_list.txt"), emit: node_list
    // path "versions.yml"                      , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    """
    awk '\$1 == "${meta.tax_id}" { print \$3 }' ${taxdb_dir}/taxDB > node_list.txt
    """
}

process MAKENODELIST {
    tag "$meta.id"
    label 'process_single'

    conda "conda-forge::gawk=5.3.0"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/gawk:5.3.0' :
        'biocontainers/gawk:5.3.0' }"

    input:
    tuple val(meta), val(taxids)
    path taxdb_dir

    output:
    tuple val(meta), path("*.node_list.txt", arity: '1..*'), emit: node_lists
    tuple val("${task.process}"), val('gawk'), eval("awk -Wversion | sed '1!d; s/.*Awk //; s/,.*//'"), topic: versions, emit: versions_gawk

    when:
    task.ext.when == null || task.ext.when

    script:
    """
    awk -F'\\t' -v taxids="${taxids.join(',')}" '
        BEGIN { n = split(taxids, arr, ","); for (i = 1; i <= n; i++) want[arr[i]] = 1 }
        (\$1 in want) { print \$3 > (\$1 ".node_list.txt") }
    ' ${taxdb_dir}/taxDB
    """

    stub:
    """
    ${taxids.collect{ taxid -> "touch ${taxid}.node_list.txt" }.join('\n')}
    """
}

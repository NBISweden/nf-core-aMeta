process MALT_QUANTIFYABUNDANCE {
    tag "$meta.id"
    label 'process_single'

    conda "conda-forge::python=3.8.3"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/python:3.8.3' :
        'biocontainers/python:3.8.3' }"

    input:
    tuple val(meta), path(sam)
    path unique_taxids

    output:
    tuple val(meta), path("*_counts.txt"), emit: counts
    tuple val("${task.process}"), val('python'), eval("python --version 2>&1 | sed 's/Python //g'"), topic: versions, emit: versions_python

    when:
    task.ext.when == null || task.ext.when

    script:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    malt_quantify_abundance.py $sam $unique_taxids > ${prefix}.sam_counts.txt
    """

    stub:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    touch ${prefix}.sam_counts.txt
    """
}

process KRAKENUNIQ_TOKRONA {
    tag "$meta.id"
    label 'process_single'

    conda "conda-forge::pandas=1.5.2"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/pandas:1.5.2':
        'biocontainers/pandas:1.5.2' }"

    input:
    tuple val(meta), path(report), path(sequences)

    output:
    tuple val(meta), path("*_taxIDs_kmers1000.txt")           , emit: taxid_txt
    tuple val(meta), path("${sequences.name}_kmers1000.txt")  , emit: sequence_txt
    tuple val(meta), path("${sequences.name}_kmers1000.krona"), emit: krona
    tuple val("${task.process}"), val('python'), eval("python --version 2>&1 | sed 's/Python //g'"), topic: versions, emit: versions_python
    tuple val("${task.process}"), val('pandas'), eval("python -c \"import pkg_resources; print(pkg_resources.get_distribution('pandas').version)\""), topic: versions, emit: versions_pandas

    when:
    task.ext.when == null || task.ext.when

    script:
    """
    krakenuniq2krona.py \\
        $report \\
        $sequences

    cat ${sequences.name}_kmers1000.txt | cut -f 2,3 > ${sequences.name}_kmers1000.krona
    """

    stub:
    """
    touch ${sequences.name}_taxIDs_kmers1000.txt
    touch ${sequences.name}_kmers1000.txt
    touch ${sequences.name}_kmers1000.krona
    """
}

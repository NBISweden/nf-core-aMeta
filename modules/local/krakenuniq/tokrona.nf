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
    path "versions.yml"                                       , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    krakenuniq2krona.py \\
        $report \\
        $sequences

    cat ${sequences.name}_kmers1000.txt | cut -f 2,3 > ${sequences.name}_kmers1000.krona

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        python: \$(python --version 2>&1 | sed 's/Python //g')
        pandas: \$(python -c "import pkg_resources; print(pkg_resources.get_distribution('pandas').version)")
    END_VERSIONS
    """

    stub:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    touch ${report.name}_taxID_kmers1000.txt
    touch ${sequences.name}_kmers1000.txt

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        python: \$(python --version 2>&1 | sed 's/Python //g')
        pandas: \$(python -c "import pkg_resources; print(pkg_resources.get_distribution('pandas').version)")
    END_VERSIONS
    """
}

process KRAKENUNIQ_FILTER {
    tag "$meta.id"
    label 'process_single'

    conda "conda-forge::pandas=1.5.2"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/pandas:1.5.2':
        'biocontainers/pandas:1.5.2' }"

    input:
    tuple val(meta), path(report)
    val n_unique_kmers
    val n_tax_reads
    path pathogenomes_found

    output:
    tuple val(meta), path("${report}.pathogens")    , emit: pathogens
    tuple val(meta), path("${report}.filtered")     , emit: filtered
    tuple val(meta), path("*.taxID.pathogens")      , emit: pathogen_tax_id
    tuple val(meta), path("*.taxID.species")        , emit: species_tax_id
    tuple val(meta), path("*.krakenuniq_filter.log"), emit: log
    path "versions.yml"                             , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    filter_krakenuniq.py \\
        $report \\
        $n_unique_kmers \\
        $n_tax_reads \\
        $pathogenomes_found \\
        | tee ${prefix}.krakenuniq_filter.log

    cut -f7 ${report}.pathogens | tail -n +2 > ${prefix}.taxID.pathogens
    cut -f7 ${report}.filtered | tail -n +2 > ${prefix}.taxID.species

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
    touch ${prefix}.krakenuniq.output.pathogens
    touch ${prefix}.krakenuniq.output.filtered
    touch ${prefix}.taxID.species
    touch ${prefix}.taxID.pathogens

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        python: \$(python --version 2>&1 | sed 's/Python //g')
        pandas: \$(python -c "import pkg_resources; print(pkg_resources.get_distribution('pandas').version)")
    END_VERSIONS
    """
}

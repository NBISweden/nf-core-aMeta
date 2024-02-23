process MALT_QUANTIFYABUNDANCE {
    tag "$meta.id"
    label 'process_single'

    // TODO: Fix container and versions string
    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/YOUR-TOOL-HERE':
        'biocontainers/YOUR-TOOL-HERE' }"

    input:
    tuple val(meta), path(sam)
    path unique_taxids

    output:
    tuple val(meta), path("*.counts"), emit: counts
    path "versions.yml"              , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    malt_quantify_abundance.py $sam $unique_taxids > ${prefix}.sam_counts.txt

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        malt: \$(samtools --version |& sed '1!d ; s/samtools //')
    END_VERSIONS
    """
}

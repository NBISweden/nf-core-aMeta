process READLENGTHDISTRIBUTION {
    tag "$meta.id"
    label 'process_single'

    conda "bioconda::samtools:1.19.2"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/samtools:1.19.2--h50ea8bc_0' :
        'biocontainers/samtools:1.19.2--h50ea8bc_0' }"

    input:
    tuple val(meta), path(bam)

    output:
    tuple val(meta), path("*.read_length.txt"), emit: read_length
    path "versions.yml"           , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    samtools \\
        view \\
        $args \\
        $bam \\
        | awk '{ print length(\$10) }' > ${prefix}.read_length.txt

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        readlengthdistribution: \$(samtools --version |& sed '1!d ; s/samtools //')
    END_VERSIONS
    """
}

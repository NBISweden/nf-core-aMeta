process PMDTOOLS_DEAMINATION {
    tag "$meta.id"
    label 'process_single'

    conda "bioconda::pmdtools=0.60"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/pmdtools:0.60--hdfd78af_5' :
        'biocontainers/pmdtools:0.60--hdfd78af_5' }"

    input:
    tuple val(meta), path(bam)

    output:
    tuple val(meta), path("*.bam"), emit: bam
    path "versions.yml"           , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    (samtools view {input.bam} || true) \\
        | pmdtools --platypus --number 2000000 > PMD_temp.txt
    R CMD BATCH $(which plotPMD)

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        pmdtools: \$(samtools --version |& sed '1!d ; s/samtools //')
    END_VERSIONS
    """
}

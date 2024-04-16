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
    tuple val(meta), path("*.PMD_temp.txt"), emit: pmd_temp
    tuple val(meta), path("*.PMD_plot.frag.pdf"), emit: pmd_plot_frag
    path "versions.yml"           , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    (samtools view $bam || true) \\
        | pmdtools --platypus --number 2000000 > PMD_temp.txt
    R CMD BATCH \$(which plotPMD)
    mv PMD_temp.txt ${prefix}.PMD_temp.txt
    mv PMD_plot.frag.pdf ${prefix}.PMD_plot.frag.pdf

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        pmdtools: \$(pmdtools --version | sed 's/.*v//')
        samtools: \$(samtools --version |& sed '1!d ; s/samtools //')
    END_VERSIONS
    """
}

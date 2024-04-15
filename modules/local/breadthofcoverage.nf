process BREADTHOFCOVERAGE {
    tag "$meta.id"
    label 'process_single'

    conda "bioconda::samtools:1.18"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/samtools:1.18--h50ea8bc_1' :
        'biocontainers/samtools:1.18--h50ea8bc_1' }"

    input:
    tuple val(meta), path(sam)
    path fasta // malt_nt_fasta
    path fai   // malt_nt_fasta

    output:
    tuple val(meta), path("name_list.txt"), emit: name_list
    tuple val(meta), path("*.sorted.bam"), emit: sorted_bam
    tuple val(meta), path("*.breath_of_coverage"), emit: breath_of_coverage
    path "versions.yml"           , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    // TODO add prefix to filenames
    """
    echo "${meta.taxid}" > name_list.txt
    zcat $sam | grep "${meta.taxid}" | uniq > ${meta.taxid}.sam
    samtools view -bS ${meta.taxid}.sam > ${meta.taxid}.bam
    samtools sort ${meta.taxid}.bam ${meta.taxid}.sorted.bam
    samtools index ${meta.taxid}.sorted.bam
    samtools depth -a ${meta.taxid}.sorted.bam > ${meta.taxid}.breath_of_coverage
    grep -w -f name_list.txt $fai | \\
        awk '{printf(\\"%s:1-%s\\\\n\\", \$1, \$2)}' \\
        > name_list.txt.regions
    samtools faidx $fasta -r name_list.txt.regions -o ${meta.taxid}.fasta
    rm ${meta.taxid}.sam

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        samtools: \$(samtools --version |& sed 's/^.*samtools //; s/Using.*\$//')
    END_VERSIONS
    """
}

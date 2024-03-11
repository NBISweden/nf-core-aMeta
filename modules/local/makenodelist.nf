process MAKENODELIST {
    tag "$meta.id"
    label 'process_single'

    input:
    tuple val(meta)
    path tax_db

    output:
    tuple val(meta), val(node_list), emit: node_list
    // path "versions.yml"           , emit: versions

    when:
    task.ext.when == null || task.ext.when

    exec:
    //TODO: "awk -v var={wildcards.taxid} '{{ if($1==var) print $0 }}' {params.tax_db}/taxDB | cut -f3 > {output.node_list}"

    // script:
    // def args = task.ext.args ?: ''
    // def prefix = task.ext.prefix ?: "${meta.id}"
    // """
    // samtools \\
    //     sort \\
    //     $args \\
    //     -@ $task.cpus \\
    //     -o ${prefix}.bam \\
    //     -T $prefix \\
    //     $bam

    // cat <<-END_VERSIONS > versions.yml
    // "${task.process}":
    //     makenodelist: \$(samtools --version |& sed '1!d ; s/samtools //')
    // END_VERSIONS
    // """
}

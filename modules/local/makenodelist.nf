process MAKENODELIST {
    tag "$meta.id"
    label 'process_single'

    input:
    val meta
    val taxdb_dir // Output of collect, so input is a list of a path

    output:
    tuple val(meta), path("node_list.txt"), emit: node_list
    // path "versions.yml"                      , emit: versions

    when:
    task.ext.when == null || task.ext.when

    exec:
    taxDB = taxdb_dir[0].resolve("taxDB")
    records = taxDB.splitCsv(header: ['tax_id', 'parent_id', 'name', 'rank'], sep: '\t')
        .findAll{ it.tax_id == meta.taxid }
        .collect{ it.name }
    file("$task.workDir/node_list.txt").text = records.join('\n')
    // script:
    // //TODO: "awk -v var={wildcards.taxid} '{{ if($1==var) print $0 }}' {params.tax_db}/taxDB | cut -f3 > {output.node_list}"
    // """
    // awk -F \$'\\t' -v var=${taxid_list.text} '{{ if(\$1==var) print $3 }}' > node_list

    // cat <<-END_VERSIONS > versions.yml
    // "${task.process}":
    //     makenodelist: \$(samtools --version |& sed '1!d ; s/samtools //')
    // END_VERSIONS
    // """
}

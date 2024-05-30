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
}

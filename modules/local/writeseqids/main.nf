process WRITESEQIDS {
    tag "$meta.id"
    label 'process_single'

    input:
    tuple val(meta), path(bam), path(bai)

    output:
    tuple val(meta), path("*.seq_ids"), emit: seq_ids

    when:
    task.ext.when == null || task.ext.when

    exec:
    // Used in place of collectFile
    def prefix = task.ext.prefix ?: meta.taxid
    file("$task.workDir/${prefix}.seq_ids").text = meta.seqids.join('\n')
}

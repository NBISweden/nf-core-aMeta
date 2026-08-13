process MALT_PREPAREDB {
    label 'process_single'

    conda "bioconda::htslib=1.23.1 bioconda::samtools=1.23.1"
    container "${ workflow.containerEngine in ['singularity', 'apptainer'] && !task.ext.singularity_pull_docker_container ?
        'https://community-cr-prod.seqera.io/docker/registry/v2/blobs/sha256/8c/8c5d2818c8b9f58e1fba77ce219fdaf32087ae53e857c4a496402978af26e78c/data' :
        'community.wave.seqera.io/library/htslib_samtools:1.23.1--5b6bb4ede7e612e5' }"

    input:
    path unique_taxids
    path seqid2taxid
    path nt_fasta

    output:
    path "seqid2taxid.project.map", emit: project_map
    path "seqids.project"         , emit: project
    path "library.project.fna"    , emit: library
    tuple val("${task.process}"), val('samtools'), eval("samtools --version |& sed '1!d; s/samtools //'"), topic: versions, emit: versions_samtools

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    """
    grep -wFf $unique_taxids $seqid2taxid > seqid2taxid.project.map
    cut -f1 seqid2taxid.project.map > seqids.project
    samtools faidx \\
        $args \\
        $nt_fasta \\
        -r seqids.project \\
        > library.project.fna
    """

    stub:
    """
    touch seqid2taxid.project.map
    touch seqids.project
    touch library.project.fna
    """
}

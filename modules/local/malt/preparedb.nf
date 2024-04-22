process MALT_PREPAREDB {
    label 'process_single'

    conda "bioconda::seqtk=1.4"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/seqtk:1.4--he4a0461_1' :
        'biocontainers/seqtk:1.4--he4a0461_1' }"

    input:
    path unique_taxids
    path seqid2taxid
    path nt_fasta

    output:
    path "seqid2taxid.project.map", emit: project_map
    path "seqids.project"         , emit: project
    path "project.headers"        , emit: headers
    path "library.project.fna"    , emit: library
    path "versions.yml"           , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    """
    grep -wFf $unique_taxids $seqid2taxid > seqid2taxid.project.map
    cut -f1 seqid2taxid.project.map > seqids.project
    grep -Ff seqids.project $nt_fasta | sed 's/>//g' > project.headers
    seqtk \\
        subseq \\
        $args \\
        $nt_fasta \\
        project.headers \\
        > library.project.fna

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        seqtk: \$( seqtk |& sed '3!d; s/.* //; s/-.*//' )
    END_VERSIONS
    """
}

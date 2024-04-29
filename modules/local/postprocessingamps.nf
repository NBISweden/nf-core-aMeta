process POSTPROCESSINGAMPS {
    tag "$meta.id"
    label 'process_medium'

    conda "bioconda::hops:0.35"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/hops:0.35--hdfd78af_1' :
        'biocontainers/hops:0.35--hdfd78af_1' }"

    input:
    tuple val(meta), path(node_list), path(malt_extract)

    output:
    tuple val(meta), path("$malt_extract/analysis.RData")            , emit: rdata
    tuple val(meta), path("$malt_extract/heatmap_overview_Wevid.pdf"), emit: heatmap_pdf
    tuple val(meta), path("$malt_extract/heatmap_overview_Wevid.tsv"), emit: heatmap_tsv
    path "versions.yml"                                              , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    postprocessing.AMPS.r \\
        $args \\
        -m def_anc \\
        -r $malt_extract \\
        -t ${task.cpus} \\
        -n $node_list \\
        || { echo 'postprocessing failed for ${meta.id}_${meta.taxid}' \\
        > $malt_extract/analysis.RData; }

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        r-base: \$(R --version |& sed '1!d; s/R version //; s/ .*//')
    END_VERSIONS
    """
}

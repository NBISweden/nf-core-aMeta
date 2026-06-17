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
    tuple val(meta), path("$malt_extract/pdf_candidate_profiles")    , emit: pdf_candidate_profiles
    tuple val("${task.process}"), val('r-base'), eval("R --version |& sed '1!d; s/R version //; s/ .*//'"), topic: versions, emit: versions_rbase

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    """
    postprocessing.AMPS.r \\
        $args \\
        -m def_anc \\
        -r $malt_extract \\
        -t ${task.cpus} \\
        -n $node_list \\
        || { echo 'postprocessing failed for ${meta.id}_${meta.taxid}' \\
        > $malt_extract/analysis.RData; }
    """

    stub:
    """
    mkdir -p ${malt_extract}/pdf_candidate_profiles
    touch ${malt_extract}/analysis.RData
    touch ${malt_extract}/heatmap_overview_Wevid.pdf
    touch ${malt_extract}/heatmap_overview_Wevid.tsv
    """
}

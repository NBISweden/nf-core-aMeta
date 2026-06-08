process AUTHENTICATIONPLOTS {
    tag "$meta.id"
    label 'process_single'

    conda "bioconda::hops:0.35 conda-forge::imagemagick:7.1.2_25"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://community-cr-prod.seqera.io/docker/registry/v2/blobs/sha256/26/267bf07e07eb7d35f919eebad086a6a5f99b8f9a5c0a252c4f184a4512e6cfe6/data' :
        'community.wave.seqera.io/library/hops_imagemagick:64fc3ff30654cafe' }"

    input:
    tuple( val(meta), path(node_list, stageAs: 'node_list.txt'), path(read_length, stageAs:'read_length.txt'), path(pmd_scores, stageAs: 'PMDscores.txt'), path(breadth_of_coverage, stageAs: 'breadth_of_coverage'), path(name_list, stageAs: 'name_list.txt'), path(maltextract_results, stageAs: 'MaltExtract_output') )

    output:
    tuple val(meta), path("*.pdf"), emit: pdf
    tuple val("${task.process}"), val('r-base'), eval("R --version |& sed '1!d; s/R version //; s/ .*//'"), topic: versions, emit: versions_rbase

    when:
    task.ext.when == null || task.ext.when

    script:
    """
    ID=\$( find -L MaltExtract_output -wholename "*/default/editDistance/*_editDistance.txt" -exec basename {} "_editDistance.txt" \\; )
    authentic.R ${meta.taxid} "\$ID" .
    """
}

process MALT_ABUNDANCEMATRIXSAM {
    label 'process_single'

    conda "conda-forge::r-base:4.3.3 conda-forge::r-pheatmap:1.0.12"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'oras://community.wave.seqera.io/library/r-pheatmap:1.0.12--d3684be95dc92871' :
        'community.wave.seqera.io/library/r-pheatmap:1.0.12--07179b67a66cda52' }"

    input:
    path counts, stageAs: 'counts/*'
    path species_names_list, stageAs: 'unique_species_names_list.txt'

    output:
    path "malt_abundance_matrix_sam.txt", emit: abundance_matrix_sam
    tuple val("${task.process}"), val('r-base'), eval("R --version |& sed '1!d; s/R version //; s/ .*//'"), topic: versions, emit: versions_rbase
    tuple val("${task.process}"), val('pheatmap'), eval("Rscript -e \"cat(as.character(packageVersion('pheatmap')))\""), topic: versions, emit: versions_pheatmap

    when:
    task.ext.when == null || task.ext.when

    script:
    """
    malt_abundance_matrix.R counts/ ./
    """

    stub:
    """
    touch malt_abundance_matrix_sam.txt
    """
}

process MALT_ABUNDANCEMATRIXSAM {
    label 'process_single'

    conda "conda-forge::r-base conda-forge::r-pheatmap"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'oras://community.wave.seqera.io/library/r-pheatmap:1.0.12--d3684be95dc92871' :
        'community.wave.seqera.io/library/r-pheatmap:1.0.12--07179b67a66cda52' }"

    input:
    path counts, stageAs: 'counts/*'
    path species_names_list, stageAs: 'unique_species_names_list.txt'

    output:
    path "malt_abundance_matrix_sam.txt", emit: abundance_matrix_sam
    path "versions.yml"                 , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    """
    malt_abundance_matrix.R counts/ ./

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        r-base: \$(R --version |& sed '1!d; s/R version //; s/ .*//')
        pheatmap: \$(Rscript -e "cat(as.character(packageVersion('pheatmap')))")
    END_VERSIONS
    """
}

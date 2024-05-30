process KRAKENUNIQ_ABUNDANCEMATRIX {
    label 'process_single'

    conda "conda-forge::r-base conda-forge::r-pheatmap"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'oras://community.wave.seqera.io/library/r-pheatmap:1.0.12--d3684be95dc92871' :
        'community.wave.seqera.io/library/r-pheatmap:1.0.12--07179b67a66cda52' }"

    input:
    path reports, stageAs:'krakenuniq/*'
    val n_unique_kmers
    val n_tax_reads

    output:
    path("krakenuniq.abundance_matrix.log")            , emit: log
    path("krakenuniq_absolute_abundance_heatmap.pdf")  , emit: absolute_abundance_heatmap
    path("krakenuniq_abundance_matrix.txt")            , emit: absolute_abundance_matrix
    path("krakenuniq_normalized_abundance_heatmap.pdf"), emit: normalized_abundance_heatmap
    path("unique_species_names_list.txt")              , emit: species_names_list
    path("unique_species_taxid_list.txt")              , emit: species_taxid_list
    path "versions.yml"                                , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "krakenuniq"
    """
    krakenuniq_abundance_matrix.R \\
        krakenuniq \\
        . \\
        $n_unique_kmers \\
        $n_tax_reads \\
        |& tee ${prefix}.abundance_matrix.log
    plot_krakenuniq_abundance_matrix.R \\
        . \\
        . \\
        |& tee -a ${prefix}.abundance_matrix.log
    ls

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        r-base: \$(R --version |& sed '1!d; s/R version //; s/ .*//')
        pheatmap: \$(Rscript -e "cat(as.character(packageVersion('pheatmap')))")
    END_VERSIONS
    """

    stub:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    touch ${prefix}.bam

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        r-base: \$(R --version |& sed '1!d; s/R version //; s/ .*//')
        pheatmap: \$(Rscript -e "cat(as.character(packageVersion('pheatmap')))")
    END_VERSIONS
    """
}

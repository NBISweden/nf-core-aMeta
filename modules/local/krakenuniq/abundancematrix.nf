process KRAKENUNIQ_ABUNDANCEMATRIX {
    label 'process_single'

    conda "conda-forge::r-base:4.3.3 conda-forge::r-pheatmap:1.0.12"
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
    tuple val("${task.process}"), val('r-base'), eval("R --version |& sed '1!d; s/R version //; s/ .*//'"), topic: versions, emit: versions_rbase
    tuple val("${task.process}"), val('pheatmap'), eval("Rscript -e \"cat(as.character(packageVersion('pheatmap')))\""), topic: versions, emit: versions_pheatmap

    when:
    task.ext.when == null || task.ext.when

    script:
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
    """

    stub:
    def prefix = task.ext.prefix ?: "krakenuniq"
    """
    touch ${prefix}.abundance_matrix.log
    touch krakenuniq_absolute_abundance_heatmap.pdf
    touch krakenuniq_abundance_matrix.txt
    touch krakenuniq_normalized_abundance_heatmap.pdf
    touch unique_species_names_list.txt
    touch unique_species_taxid_list.txt
    """
}

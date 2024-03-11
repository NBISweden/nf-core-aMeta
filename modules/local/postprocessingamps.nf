process POSTPROCESSINGAMPS {
    tag "$meta.id"
    label 'process_low'

    // Using same env as krakenuniq/abundancematrix
    conda "conda-forge::r-base bioconda::bioconductor-deseq2 bioconda::bioconductor-biocparallel bioconda::bioconductor-tximport bioconda::bioconductor-complexheatmap conda-forge::r-optparse conda-forge::r-ggplot2 conda-forge::r-rcolorbrewer conda-forge::r-pheatmap"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/mulled-v2-8849acf39a43cdd6c839a369a74c0adc823e2f91:ab110436faf952a33575c64dd74615a84011450b-0' :
        'biocontainers/mulled-v2-8849acf39a43cdd6c839a369a74c0adc823e2f91:ab110436faf952a33575c64dd74615a84011450b-0' }"

    input:
    tuple val(meta), path(node_list)

    output:
    tuple val(meta), path("*.RData"), emit: rdata
    path "versions.yml"           , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    postprocessing.AMPS.r \\
        $args \\
        -m def_anc \\
        -r {params.extract} \\
        -t ${task.cpus} \\
        -n $node_list \\
        || echo 'postprocessing failed for ${meta.id}_${meta.taxid}' \\
        > analysis.RData  2> {log}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        r-base: \$(R --version |& sed 's/^.*R version //; s/ .*\$//')
        pheatmap: \$(Rscript -e "library(pheatmap); cat(as.character(packageVersion('pheatmap')))")
    END_VERSIONS
    """
}

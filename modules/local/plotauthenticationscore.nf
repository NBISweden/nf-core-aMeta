process PLOTAUTHENTICATIONSCORE {
    label 'process_single'

    conda "conda-forge::r-base:4.3.3 conda-forge::r-pheatmap:1.0.12"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'oras://community.wave.seqera.io/library/r-pheatmap:1.0.12--d3684be95dc92871' :
        'community.wave.seqera.io/library/r-pheatmap:1.0.12--07179b67a66cda52' }"

    input:
    path scores, arity: '1..*'

    output:
    path "*.pdf"       , emit: pdf
    path "*.txt"       , emit: txt
    tuple val("${task.process}"), val('r-base'), eval("R --version |& sed '1!d; s/R version //; s/ .*//'"), topic: versions, emit: versions_rbase
    tuple val("${task.process}"), val('pheatmap'), eval("Rscript -e \"cat(as.character(packageVersion('pheatmap')))\""), topic: versions, emit: versions_pheatmap

    when:
    task.ext.when == null || task.ext.when

    script:
    def dirs = scores.collectEntries{ txt -> [ txt, "scores/${txt.simpleName}/${txt.name.tokenize(".")[1]}" ] }
    def link_cmd = dirs.collect{ txt, dir -> "ln -s ../../../$txt $dir/authentication_scores.txt;"}.join("\n    ")
    """
    mkdir -p ${dirs.values().join(" ")}
    $link_cmd

    plot_score.R scores .
    """
}

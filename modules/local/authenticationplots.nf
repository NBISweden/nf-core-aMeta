process AUTHENTICATIONPLOTS {
    tag "$meta.id"
    label 'process_single'

    conda "bioconda::hops:0.35"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/hops:0.35--hdfd78af_1' :
        'biocontainers/hops:0.35--hdfd78af_1' }"

    input:
    tuple(
        val(meta),
        path(node_list, stageAs: 'node_list.txt'),
        path(read_length, stageAs:'read_length.txt'),
        path(pmd_scores, stageAs: 'PMDscores.txt'),
        path(breadth_of_coverage, stageAs: 'breadth_of_coverage'),
        path(name_list, stageAs: 'name_list.txt'),
        path(maltextract_results, stageAs: 'MaltExtract_output')
    )

    output:
    tuple val(meta), path("*.pdf"), emit: pdf
    path "versions.yml"           , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    ID=\$( find -L MaltExtract_output -wholename "*/default/editDistance/*_editDistance.txt" -exec basename {} "_editDistance.txt" \\; )
    authentic.R ${meta.taxid} "\$ID" .

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        r-base: \$(R --version |& sed '1!d; s/R version //; s/ .*//')
    END_VERSIONS
    """
}

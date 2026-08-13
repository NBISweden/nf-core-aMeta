process MALTEXTRACT {

    label 'process_medium'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine in ['singularity', 'apptainer'] && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/hops:0.35--hdfd78af_1' :
        'quay.io/biocontainers/hops:0.35--hdfd78af_1' }"

    input:
    tuple val(meta), path(rma6)
    path taxon_list
    path ncbi_dir

    output:
    tuple val(meta), path("results")      , emit: results
    tuple val(meta), path("ref_id.txt")   , emit: ref_id, optional: true
    path "versions.yml"                   , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    """
    MaltExtract \\
        -Xmx${task.memory.toGiga()}g \\
        -p $task.cpus \\
        -i ${rma6.join(' ')} \\
        -t $taxon_list \\
        -r $ncbi_dir \\
        -o results/ \\
        $args

    # Equivalent to get_ref_id() in aMeta/workflow/rules/common.smk
    REF_ID_FILE=\$( find -L results -wholename "*/default/readDist/*.rma6_additionalNodeEntries.txt" )
    if [ -f "\$REF_ID_FILE" ]; then
        REF_ID=\$( awk -F';_' 'NR==2 { print \$2 }' "\$REF_ID_FILE" )
        if [ -n "\$REF_ID" ] && [ "\$REF_ID" != "${meta.taxid}" ]; then
            echo "\$REF_ID" > ref_id.txt
        fi
    fi

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        maltextract: \$(MaltExtract --help | head -n 2 | tail -n 1 | sed 's/MaltExtract version//')
    END_VERSIONS
    """
}

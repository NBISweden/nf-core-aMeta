process BREADTHOFCOVERAGE {
    tag "$meta.id"
    label 'process_single'

    conda "bioconda::samtools:1.18"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/samtools:1.18--h50ea8bc_1' :
        'biocontainers/samtools:1.18--h50ea8bc_1' }"

    input:
    tuple val(meta), path(sam), path(malt_extract_results, stageAs: 'malt_extract_results')
    path fasta // malt_nt_fasta
    path fai   // malt_nt_fasta

    output:
    tuple val(meta), path("name_list.txt"), emit: name_list
    tuple val(meta), path("*.sorted.bam"), emit: sorted_bam
    tuple val(meta), path("*.breath_of_coverage"), emit: breadth_of_coverage
    path "versions.yml"           , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    // TODO add prefix to filenames
    """
    REF_ID="None"
    REF_ID_FILE=\$( find -L malt_extract_results -wholename "*/default/readDist/*.rma6_additionalNodeEntries.txt" )
    if [ -f "\$REF_ID_FILE" ]; then
        REF_ID=\$( awk -F';_' 'NR==2 { print \$2 }' \$REF_ID_FILE )
        if [ -z \$REF_ID ]; then
            >&2 echo "Failed to extract ref_id from \$REF_ID_FILE; returning taxid ${meta.taxid}"
            REF_ID=${meta.taxid}
        fi
    else
        >&2 echo 'No such file "malt_extract_results/default/readDist/*.rma6_additionalNodeEntries.txt"; cannot extract refid'
    fi
    echo "\$REF_ID" > name_list.txt
    zcat $sam | grep "\$REF_ID" | uniq > ${meta.taxid}.sam # TODO - grep safety
    # samtools view -bS ${meta.taxid}.sam > \$REF_ID.bam
    samtools sort ${meta.taxid}.sam -O BAM -o \$REF_ID.sorted.bam
    samtools index \$REF_ID.sorted.bam
    samtools depth -a \$REF_ID.sorted.bam > \$REF_ID.breath_of_coverage
    grep -w -f name_list.txt $fai | \\
        awk '{printf("%s:1-%s\\n", \$1, \$2)}' \\
        > name_list.txt.regions
    samtools faidx $fasta -r name_list.txt.regions -o \$REF_ID.fasta
    rm ${meta.taxid}.sam

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        samtools: \$(samtools --version | sed '1!d; s/samtools //')
    END_VERSIONS
    """
}

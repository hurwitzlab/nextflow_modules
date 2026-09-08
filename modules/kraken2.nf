#!/usr/bin/env nextflow

// Classify paired reads taxonomically with kraken2
 process kraken2 {
    container "${params.container__kraken2}"
    publishDir "${params.kraken2_outdir}", mode: 'copy'

    input:
        tuple val(sampleid), path(clean_r1), path(clean_r2)
        path(kraken2_db)

    output:
        tuple val(sampleid), path("${sampleid}.kreport"), path("${sampleid}.kraken"), emit: classification

    shell:
    '''
    kraken2 \
    --db !{kraken2_db} \
    --threads !{task.cpus} \
    --report !{sampleid}.kreport \
    --paired !{clean_r1} !{clean_r2} \
    > !{sampleid}.kraken
    '''
}

#!/usr/bin/env nextflow

// Classify contigs taxonomically with metabuli
 process metabuli {
    container "${params.container__metabuli}"
    publishDir "${params.metabuli_outdir}", mode: 'copy'

    input:
        tuple val(sampleid), path(contigs)
        path(metabuli_db)

    output:
        tuple val(sampleid), path("${sampleid}_report.tsv"), emit: classification

    shell:
    '''
    metabuli classify \
    --seq-mode 1 \
    !{contigs} \
    !{metabuli_db} \
    . \
    !{sampleid} \
    --min-score !{params.metabuli_minscore} \
    --min-sp-score !{params.metabuli_minspscore}
    '''
}

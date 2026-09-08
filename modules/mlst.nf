#!/usr/bin/env nextflow

// Call multi-locus sequence type (MLST) for a sample's assembled genome
process mlst {
    label "process_single"
    container "${params.container__mlst}"
    publishDir "${params.mlst_outdir}", mode: 'copy'

    input:
        tuple val(sampleid), path(genome)

    output:
        tuple val(sampleid), path("${sampleid}.mlst.txt"), emit: mlst_calls

    shell:
    '''
    mlst !{genome} > !{sampleid}.mlst.txt
    '''
}

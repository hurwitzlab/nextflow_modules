#!/usr/bin/env nextflow

// Determine E. coli phylotype with ezclermont
process ezclermont {
    label "process_single"
    container "${params.container__ezclermont}"
    publishDir "${params.ezclermont_outdir}", mode: 'copy'

    input:
        tuple val(sampleid), path(contigs)

    output:
        tuple val(sampleid), path("${sampleid}.phylogroup.txt"), emit: phylogroup
        tuple val(sampleid), path("${sampleid}.phylogroup.log"), emit: log

    shell:
    '''
    # ezclermont fails by default (but makes correct output), need to make a PR to fix issue
    ezclermont !{contigs} 1> !{sampleid}.phylogroup.txt 2> !{sampleid}.phylogroup.log || true
    '''
}

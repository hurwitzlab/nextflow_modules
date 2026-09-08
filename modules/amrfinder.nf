#!/usr/bin/env nextflow

// Screen a sample's assembled contigs for antimicrobial resistance genes and point mutations with AMRFinderPlus
process amrfinder {
    label "process_single"
    container "${params.container__amrfinder}"
    publishDir "${params.amrfinder_outdir}", mode: 'copy'

    input:
        tuple val(sampleid), path(contigs)

    output:
        tuple val(sampleid), path("${sampleid}.amrfinder.txt"), emit: resistance_genes

    shell:
    '''
    /bin/amrfinder --plus -n !{contigs} -O !{params.amrfinder_organism} > !{sampleid}.amrfinder.txt
    '''
}

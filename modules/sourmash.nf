#!/usr/bin/env nextflow

// Compute a MinHash signature for a sample's assembled contigs with Sourmash
process sourmash_hash {
    label "process_single"
    container "${params.container__sourmash}"
    publishDir "${params.sourmash_outdir}", mode: 'copy'

    input:
        tuple val(sampleid), path(contigs)

    output:
        tuple val(sampleid), path("contigs.sig"), emit: signature

    shell:
    '''
    sourmash compute !{contigs} --output contigs.sig
    '''
}

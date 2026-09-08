#!/usr/bin/env nextflow

// Predict CRISPR arrays in a sample's contigs with CRT and PILER-CR, then merge the results
process predict_arrays {
    label "process_single"
    container "${params.container__crispredict}"
    publishDir "${params.crispredict_outdir}", mode: 'copy'

    input:
        tuple val(sampleid), path(contigs)

    output:
        tuple val(sampleid), path("${sampleid}"), emit: crispr_predictions
        tuple val(sampleid), path("${sampleid}/combined.crispr_arrays"), emit: combined_crispr_arrays

    shell:
    '''
    predict_arrays.py -i !{contigs} -p crt -o crispr/crt/crt
    predict_arrays.py -i !{contigs} -p pilercr -o crispr/pilercr/pilercr
    integrate_arrays.py crispr/crt/crt crispr/pilercr/pilercr crispr/combined/combined

    # python scripts require outputs go into a new directory
    # copy explicitly at the end to a flat directory
    mkdir !{sampleid}
    if [ -d crispr/crt ];      then mv crispr/crt/* !{sampleid}/      ; fi
    if [ -d crispr/pilercr ];  then mv crispr/pilercr/* !{sampleid}/  ; fi
    if [ -d crispr/combined ]; then mv crispr/combined/* !{sampleid}/ ; fi
    '''
}

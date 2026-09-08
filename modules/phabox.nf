#!/usr/bin/env nextflow

// Predict phage lifestyle (virulent/temperate) with phabox2's phatyp task
 process phatyp {
    container "${params.container__phabox}"
    publishDir "${params.phabox_outdir}", mode: 'copy'

    input:
        path(viral_seqs)
        path(phabox_db)

    output:
        path("phatyp_out"), emit: lifestyle_predictions

    shell:
    '''
    phabox2 \
    --task phatyp \
    --dbdir !{phabox_db} \
    --contigs !{viral_seqs} \
    --outpth phatyp_out
    '''
}

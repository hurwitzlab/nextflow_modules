#!/usr/bin/env nextflow

// Annotate genome/plasmid sequences with bakta
 process bakta {
    container "${params.container__bakta}"
    publishDir "${params.bakta_outdir}", mode: 'copy'

    input:
        path(seqs)
        path(bakta_db)

    output:
        path("bakta_out"), emit: annotations

    shell:
    '''
    bakta \
    --db !{bakta_db} \
    -o bakta_out \
    -t !{task.cpus} \
    --force \
    !{seqs} \
    --keep-contig-headers
    '''
}

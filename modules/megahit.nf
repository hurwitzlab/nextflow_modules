#!/usr/bin/env nextflow

// Assemble paired reads into contigs with megahit
 process megahit {
    container "${params.container__megahit}"
    publishDir "${params.megahit_outdir}", mode: 'copy'

    input:
        tuple val(sampleid), path(clean_r1), path(clean_r2)

    output:
        tuple val(sampleid), path("${sampleid}/${sampleid}.contigs.fa"), emit: contigs

    shell:
    '''
    megahit \
    -t !{task.cpus} \
    --presets !{params.megahit_preset} \
    -1 !{clean_r1} \
    -2 !{clean_r2} \
    -o !{sampleid} \
    --out-prefix !{sampleid}

    rm -r !{sampleid}/intermediate_contigs
    '''
}

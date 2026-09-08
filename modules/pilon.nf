#!/usr/bin/env nextflow

// Polish an assembly using its mapped reads (NB - other files can be produced by providing a flag, e.g. --vcf, --changes)
process refine_assembly {
    label "process_high"
    container "${params.container__pilon}"
    publishDir "${params.pilon_outdir}", mode: 'copy'

    input:
        tuple val(sampleid), path(contigs), path(mapped_reads), path(mapped_reads_index)

    output:
        tuple val(sampleid), path("clean_contigs/pilon.fasta"), emit: refined_contigs

    shell:
    '''
    pilon --threads !{task.cpus} --genome !{contigs} --frags !{mapped_reads} --outdir clean_contigs
    '''
}

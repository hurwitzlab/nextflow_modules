#!/usr/bin/env nextflow

// Demultiplex raw sequencing reads from a run folder into per-sample FASTQs with bcl2fastq
process demux {
    label "process_high"
    container "${params.container__bcl2fastq}"
    publishDir "${params.bcl2fastq_outdir}", mode: 'copy'

    input:
        path(runfolder)

    output:
        path("output"), emit: demuxed_reads

    shell:
    '''
    mkdir output
    bcl2fastq --runfolder-dir !{runfolder} --output-dir output --interop-dir InterOp/
    '''
}

// Demultiplex raw sequencing reads from a run folder using an explicit sample sheet with bcl2fastq
process demux_samplesheet {
    label "process_high"
    container "${params.container__bcl2fastq}"
    publishDir "${params.bcl2fastq_outdir}", mode: 'copy'

    input:
        path(runfolder)
        path(samplesheet)

    output:
        path("output"), emit: demuxed_reads

    shell:
    '''
    mkdir output
    bcl2fastq --runfolder-dir !{runfolder} --sample-sheet !{samplesheet} --output-dir output --interop-dir InterOp/
    '''
}

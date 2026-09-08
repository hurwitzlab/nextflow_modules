#!/usr/bin/env nextflow

// Quality-trim paired reads with trimmomatic
 process trimmomatic {
    container "${params.container__trimmomatic}"
    publishDir "${params.trimmomatic_outdir}", mode: 'copy'

    input:
        tuple val(sampleid), path(bbduk_r1), path(bbduk_r2)

    output:
        tuple val(sampleid), path("${sampleid}_clean_1.fastq"), path("${sampleid}_clean_2.fastq"), emit: clean_reads

    shell:
    '''
    trimmomatic PE \
    -threads !{task.cpus} \
    !{bbduk_r1} \
    !{bbduk_r2} \
    !{sampleid}_clean_1.fastq \
    !{sampleid}_unpaired_1.fastq \
    !{sampleid}_clean_2.fastq \
    !{sampleid}_unpaired_2.fastq \
    LEADING:!{params.trimmomatic_leading} \
    TRAILING:!{params.trimmomatic_trailing} \
    SLIDINGWINDOW:!{params.trimmomatic_slidingwindow} \
    MINLEN:!{params.trimmomatic_minlen}
    '''
}

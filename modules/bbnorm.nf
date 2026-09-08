#!/usr/bin/env nextflow

// Downsample and normalize a bacterial sample's paired-end reads by k-mer depth with BBNorm
process downsample_paired_end_bacterial {
    label "process_high"
    container "${params.container__bbnorm}"
    publishDir "${params.bbnorm_outdir}", mode: 'copy'

    input:
        tuple val(sampleid), path(r1), path(r2)

    output:
        tuple val(sampleid), path("${sampleid}.r1_sub.fq.gz"), emit: r1_normalized
        tuple val(sampleid), path("${sampleid}.r2_sub.fq.gz"), emit: r2_normalized

    shell:
    '''
    # target is the aimed normalization depth
    bbnorm.sh in=!{r1} in2=!{r2} out=!{sampleid}.r1_sub.fq.gz out2=!{sampleid}.r2_sub.fq.gz target=!{params.bbnorm_kmer_cov_bacterial} mindepth=!{params.bbnorm_min_depth_bacterial} -Xmx!{Math.round(task.memory.toGiga() * 0.83)}g
    '''
}

// Downsample and normalize a phage sample's paired-end reads by k-mer depth with BBNorm
process downsample_paired_end_phage {
    label "process_high"
    container "${params.container__bbnorm}"
    publishDir "${params.bbnorm_outdir}", mode: 'copy'

    input:
        tuple val(sampleid), path(r1), path(r2)

    output:
        tuple val(sampleid), path("${sampleid}.r1_sub.fq.gz"), emit: r1_normalized
        tuple val(sampleid), path("${sampleid}.r2_sub.fq.gz"), emit: r2_normalized

    shell:
    '''
    # target is the aimed normalization depth
    bbnorm.sh in=!{r1} in2=!{r2} out=!{sampleid}.r1_sub.fq.gz out2=!{sampleid}.r2_sub.fq.gz target=!{params.bbnorm_kmer_cov_phage} mindepth=!{params.bbnorm_min_depth_phage} tossbadreads=t -Xmx!{Math.round(task.memory.toGiga() * 0.83)}g
    '''
}

// Downsample and normalize a sample's paired-end reads by k-mer depth with BBNorm
process downsample_paired_end {
    label "process_high"
    container "${params.container__bbnorm}"
    publishDir "${params.bbnorm_outdir}", mode: 'copy'

    input:
        tuple val(sampleid), path(r1), path(r2)

    output:
        tuple val(sampleid), path("${sampleid}.r1_sub.fq.gz"), emit: r1_normalized
        tuple val(sampleid), path("${sampleid}.r2_sub.fq.gz"), emit: r2_normalized

    shell:
    '''
    # target is the aimed normalization depth
    bbnorm.sh in=!{r1} in2=!{r2} out=!{sampleid}.r1_sub.fq.gz out2=!{sampleid}.r2_sub.fq.gz target=!{params.bbnorm_target} -Xmx!{Math.round(task.memory.toGiga() * 0.83)}g
    '''
}

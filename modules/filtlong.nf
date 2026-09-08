#!/usr/bin/env nextflow

// Filter and downsample a sample's long reads toward a phage-scale target depth
// (phage genomes usually range 30-180kb, so 40M target bases gives decent coverage for long-read assembly >~200X)
process filtlong_qc_downsample_phage {
    label "process_single"
    container "${params.container__filtlong}"

    input:
        tuple val(sampleid), path(reads)

    output:
        tuple val(sampleid), path("${sampleid}_downsampled.fq.gz"), emit: downsampled_reads

    shell:
    '''
    filtlong --min_length 1000 --target_bases 40000000 !{reads} | gzip > !{sampleid}_downsampled.fq.gz
    '''
}

// Lightly quality-filter a sample's long reads, keeping the best 95%
process filtlong_light_qc {
    label "process_single"
    container "${params.container__filtlong}"

    input:
        tuple val(sampleid), path(reads)

    output:
        tuple val(sampleid), path("${sampleid}_qc.fq.gz"), emit: qc_reads

    shell:
    '''
    filtlong --min_length 1000 --keep_percent 95 !{reads} | gzip > !{sampleid}_qc.fq.gz
    '''
}

// Filter a sample's ONT reads by minimum length
process filter_ont_reads_by_length {
    label "process_single"
    container "${params.container__filtlong}"

    input:
        tuple val(sampleid), path(reads)

    output:
        tuple val(sampleid), path("${sampleid}_filtered.fq.gz"), emit: filtered_reads

    shell:
    '''
    filtlong --min_length 1000 !{reads} | gzip > !{sampleid}_filtered.fq.gz
    '''
}

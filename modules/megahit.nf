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

// Assemble paired-end reads into contigs with MEGAHIT
process megahit_paired_end {
    label "process_high"
    container "${params.container__megahit}"
    publishDir "${params.megahit_outdir}", mode: 'copy'

    input:
        tuple val(sampleid), path(r1), path(r2)

    output:
        tuple val(sampleid), path("megahit_out/final.contigs.fa"), emit: contigs
        tuple val(sampleid), path("megahit_out/log"), emit: log_file
        tuple val(sampleid), path("megahit_out/options.json"), emit: options

    shell:
    '''
    megahit -1 !{r1} \
            -2 !{r2} \
            --min-contig-len 200 \
            --min-count 2 \
            --low-local-ratio 0.2 \
            --no-mercy \
            --num-cpu-threads !{task.cpus}

    if [ ! -s megahit_out/final.contigs.fa ]; then
        exit 1
    fi
    '''
}

// Assemble single-end reads into contigs with MEGAHIT
process megahit_single_end {
    label "process_high"
    container "${params.container__megahit}"
    publishDir "${params.megahit_outdir}", mode: 'copy'

    input:
        tuple val(sampleid), path(reads)

    output:
        tuple val(sampleid), path("megahit_out/final.contigs.fa"), emit: contigs
        tuple val(sampleid), path("megahit_out/log"), emit: log_file
        tuple val(sampleid), path("megahit_out/options.json"), emit: options

    shell:
    '''
    megahit --read !{reads} \
            --min-contig-len 200 \
            --min-count 2 \
            --low-local-ratio 0.2 \
            --no-mercy \
            --num-cpu-threads !{task.cpus}

    if [ ! -s megahit_out/final.contigs.fa ]; then
        exit 1
    fi
    '''
}

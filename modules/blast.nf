#!/usr/bin/env nextflow

// Build a nucleotide BLAST database and search it with blastn

// Build a nucleotide BLAST database from a fasta file
 process makeblastdb {
    container "${params.container__blast}"

    input:
        tuple val(sampleid), path(fasta_seqs)

    output:
        tuple val(sampleid), path("${sampleid}_db*"), emit: blast_db

    shell:
    '''
    makeblastdb \
    -in !{fasta_seqs} \
    -out !{sampleid}_db \
    -dbtype nucl
    '''
}

// Search a query fasta against a BLAST database with blastn
 process blastn {
    container "${params.container__blast}"
    publishDir "${params.blast_outdir}", mode: 'copy'

    input:
        tuple val(sampleid), path(query_seqs), path(blast_db)

    output:
        tuple val(sampleid), path("${sampleid}_blast.out"), emit: hits

    shell:
    '''
    blastn \
    -db !{sampleid}_db \
    -query !{query_seqs} \
    -outfmt 6 \
    -out !{sampleid}_blast.out \
    -max_hsps !{params.blast_max_hsps} \
    -evalue !{params.blast_evalue}
    '''
}

#!/usr/bin/env nextflow

// Cluster sequences into representative OTU-style clusters with mmseqs2 easy-cluster
process mmseqs_cluster {
    container "${params.container__mmseqs2}"
    publishDir "${params.mmseqs2_outdir}", mode: 'copy'

    input:
        path(all_seqs)

    output:
        path("${params.mmseqs2_prefix}_rep_seq.fasta"), emit: representative_seqs
        path("${params.mmseqs2_prefix}_cluster.tsv"), emit: clusters

    shell:
    '''
    mmseqs easy-cluster \
    !{all_seqs} \
    !{params.mmseqs2_prefix} \
    tmp \
    --min-seq-id !{params.mmseqs2_minseqid} \
    --cov-mode !{params.mmseqs2_covmode} \
    -c !{params.mmseqs2_c} \
    --threads !{task.cpus}
    '''
}

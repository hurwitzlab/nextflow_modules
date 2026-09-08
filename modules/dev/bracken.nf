#!/usr/bin/env nextflow

// Re-estimate species abundance from a kraken2 report with bracken
process bracken {
    label "process_high"
    container "${params.container__bracken}"
    publishDir "${params.bracken_outdir}", mode: 'copy'

    input:
        // The kmer distributions bracken needs to run are bundled with the kraken database,
        // this may change later as bracken / kraken / centrifuge database construction is automated.
        // kreport is staged under a fixed name because bracken derives the updated-kreport
        // output filename from the input report's basename (not settable via a flag).
        tuple val(sampleid), path(kreport, stageAs: "in.kreport")
        path(kraken2_db)
        val(kmer_size)

    output:
        tuple val(sampleid), path("${sampleid}.bracken_stats.txt"),   emit: bracken_stats
        tuple val(sampleid), path("${sampleid}.bracken_species.kreport"), emit: bracken_kreport

    shell:
    '''
    mkdir kraken_db
    tar -xvf !{kraken2_db} -C kraken_db

    python /Bracken-2.6.2/src/est_abundance.py \
            -i in.kreport \
            -o !{sampleid}.bracken_stats.txt \
            -k kraken_db/database!{kmer_size}mers.kmer_distrib

    mv in_bracken_species.kreport !{sampleid}.bracken_species.kreport
    '''
}

#!/usr/bin/env nextflow

// Identify plasmids in assembled contigs
process plasmidfinder {
    label "process_single"
    container "${params.container__plasmidfinder}"
    publishDir "${params.plasmidfinder_outdir}", mode: 'copy'

    input:
        tuple val(sampleid), path(contigs)
        path(database)

    output:
        tuple val(sampleid), path("plasmidfinder.json"), emit: plasmid_predictions

    shell:
    '''
    mkdir database_dir
    tar -xvf !{database} -C database_dir

    # produces data.json
    plasmidfinder.py -i !{contigs} -p database_dir -q
    mv data.json plasmidfinder.json
    '''
}

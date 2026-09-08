#!/usr/bin/env nextflow

// Call bacterial serotype from a sample's assembled contigs using SerotypeFinder
process serotypefinder {
    label "process_single"
    container "${params.container__serotypefinder}"
    publishDir "${params.serotypefinder_outdir}", mode: 'copy'

    input:
        tuple val(sampleid), path(contigs)
        path(database)

    output:
        tuple val(sampleid), path("${sampleid}.serotype.json"), emit: serotype_calls

    shell:
    '''
    mkdir database
    tar -xvf !{database} -C database

    serotypefinder.py --infile !{contigs} --databasePath database > !{sampleid}.serotype.json
    '''
}

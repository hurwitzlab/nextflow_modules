#!/usr/bin/env nextflow

// Render a sample's assembly graph to an image with Bandage
process visualize_assembly {
    label "process_single"
    container "${params.container__bandage}"
    publishDir "${params.bandage_outdir}", mode: 'copy'

    input:
        tuple val(sampleid), path(gfa)

    output:
        tuple val(sampleid), path("${sampleid}.svg"), emit: assembly_graph_image

    shell:
    '''
    Bandage image !{gfa} !{sampleid}.svg
    '''
}

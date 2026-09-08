#!/usr/bin/env nextflow

// Describe what this process does in plain terms, e.g. "Infer viral sequences using <tool>"
 process TOOLNAME {
    label "process_medium"                                // process_single | process_low | process_medium | process_high
    container "${params.container__TOOLNAME}"
    publishDir "${params.TOOLNAME_outdir}", mode: 'copy'   // omit for purely intermediate steps

    input:
        tuple val(sampleid), path(contigs)
        // path(some_db)                                  // reference databases are separate inputs, not folded into the tuple

    output:
        tuple val(sampleid), path("${sampleid}"), emit: descriptive_output_name

    shell:
    '''
    toolname \
    -i !{contigs} \
    -o !{sampleid} \
    -t !{task.cpus} \
    -l !{params.TOOLNAME_some_option}
    '''
}

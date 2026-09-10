#!/usr/bin/env nextflow

// Describe what this process does in plain terms, e.g. "Infer viral sequences using <tool>"
 process TOOLNAME {
    label "process_medium"                                // process_single | process_low | process_medium | process_high
    label "publish_final"                                 // publish_intermediate | publish_final -- omit both + no publishDir for purely intermediate steps
    container "${params.container__TOOLNAME}"
    // No publishDir here -- the consuming pipeline's conf/base.config gives
    // this a publishDir via its withLabel:publish_final block (see
    // modules/CLAUDE.md). Only use a process with no `sampleid` below (a
    // reference index, a cross-sample merge/compare, a whole-batch/run step)
    // needs the older in-module form instead -- see modules/CLAUDE.md's
    // publishDir exception.

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

#!/usr/bin/env nextflow

// Query a single-end read against spaced-seed sketches at multiple window/length parameters
process spaced_seed_sketch_single_read {
    label "process_low"
    container "${params.container__sketch}"
    publishDir "${params.sketch_outdir}", mode: 'copy'

    input:
        tuple val(sampleid), path(r1)
        path(sketch_seed)

    output:
        tuple val(sampleid), path("query_output_seed_w14l15.csv"), emit: query_output_seed_w14l15
        tuple val(sampleid), path("query_output_seed_w20l21.csv"), emit: query_output_seed_w20l21
        tuple val(sampleid), path("query_output_seed_w28l29.csv"), emit: query_output_seed_w28l29
        tuple val(sampleid), path("query_output_seed_w30l61.csv"), emit: query_output_seed_w30l61

    shell:
    '''
    tar -xvf !{sketch_seed}
    # get spaced seed content for multiple spaced seed sketches of w14l15, w20l21, w28l29, w30l61
    for seed in w14l15 w20l21 w28l29 w30l61; do
        querysseed --sample_id !{sampleid} -t !{task.cpus} --r1 !{r1} --ref sketch_seed/ss_sketch_$seed.txt -o query_output_seed_$seed.csv
    done
    '''
}

#!/usr/bin/env nextflow

// Bin a sample's contigs into genome bins using assembly + JGI depth profile
process bin_contigs {
    label "process_medium"
    container "${params.container__vamb}"
    publishDir "${params.vamb_outdir}", mode: 'copy'

    input:
        tuple val(sampleid), path(contigs), path(depth_file)

    output:
        tuple val(sampleid), path("out_results/bins"), emit: genome_bins
        tuple val(sampleid), path("bin_names.json"), emit: bin_name_map
        tuple val(sampleid), path("out_results/clusters.tsv"), emit: cluster_assignments
        tuple val(sampleid), path("out_results/log.txt"), emit: run_log

    shell:
    '''
    vamb --outdir out_results --fasta !{contigs} --jgi !{depth_file} --minfasta 200000 -t !{task.cpus}
    python -c 'import os, json; print(json.dumps({x: value for x, value in enumerate(os.listdir("out_results/bins"))}))' > bin_names.json
    '''
}

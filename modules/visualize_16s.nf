#!/usr/bin/env nextflow

// Generate ASV/genus-level summary tables and a genus breakdown plot from a taxonomy + feature table
process visualize_16s {
    label "process_low"
    container "${params.container__visualize_16s}"
    publishDir "${params.visualize_16s_outdir}", mode: 'copy'

    input:
        path(taxonomy)
        path(feature_table)

    output:
        path "visualize_output/asv_table.tsv", emit: asv_table
        path "visualize_output/nr_table.tsv", emit: nr_table
        path "visualize_output/genus_breakdown.png", emit: genus_breakdown_plot

    shell:
    '''
    asv_table_viz.py --table_df !{feature_table} --taxonomy_df !{taxonomy} --asv_out asv_table.tsv --nr_out nr_table.tsv --plot_out genus_breakdown.png
    '''
}

// Build a checkfile from the non-redundant ASV table for downstream validation
process make_checkfile {
    label "process_low"
    container "${params.container__visualize_16s}"
    publishDir "${params.visualize_16s_outdir}", mode: 'copy'

    input:
        path(nr_table)

    output:
        path "checkfile.tsv", emit: checkfile

    shell:
    '''
    cut --complement -f2 !{nr_table} > checkfile.tsv
    '''
}

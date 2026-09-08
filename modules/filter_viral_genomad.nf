#!/usr/bin/env nextflow

// Processes for all the tools in bbmap

// Run the R script that filters genomad viral contig inference based on coverage and checkV output
 process filter_viral_contigs {
                        
    input:
        tuple val(sampleid), path(contigs), path(clean_r1), path(clean_r2)

    output:
        tuple val(sampleid), path("${sampleid}_aln.sam.gz"), emit: mapped_files

    shell:
    '''

    '''
}

// Run the python script that extracts the fasta sequences from the viral contigs that passed filtering
 process extract_fasta_viral_selection {
    container "${params.container__bbmap}"
    publishDir "${params.bbmap_outdir}", mode: 'copy'
                        
    input:
        tuple val(sampleid), path(aligned_sam)

    output:
        tuple val(sampleid), path("${sampleid}_cov.txt"), emit: pileuped_files

    shell:
    '''

    '''

 }
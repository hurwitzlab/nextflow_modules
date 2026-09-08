#!/usr/bin/env nextflow

// Identify prophage sequences in a sample's contigs using VIBRANT
// https://github.com/AnantharamanLab/VIBRANT
process vibrant {
    label "process_high"
    container "${params.container__vibrant}"
    publishDir "${params.vibrant_outdir}", mode: 'copy'

    input:
        tuple val(sampleid), path(contigs)
        path(vibrant_db_archive)
        path(vibrant_files_archive)

    output:
        tuple val(sampleid), path("VIBRANT_${contigs.baseName}/VIBRANT_phages_${contigs.baseName}/${contigs.baseName}.phages_combined.fna"), emit: phage_sequences
        tuple val(sampleid), path("VIBRANT_${contigs.baseName}/VIBRANT_figures_${contigs.baseName}"), emit: vibrant_figures
        tuple val(sampleid), path("VIBRANT_${contigs.baseName}/VIBRANT_phages_${contigs.baseName}"), emit: phage_predictions
        tuple val(sampleid), path("VIBRANT_${contigs.baseName}/VIBRANT_results_${contigs.baseName}"), emit: vibrant_results

    shell:
    '''
    mkdir databases
    tar -xvf !{vibrant_db_archive} -C databases
    mkdir files
    tar -xvf !{vibrant_files_archive} -C files

    base=!{contigs.baseName}

    VIBRANT_run.py -i !{contigs} \
                   -d databases \
                   -m files \
                   -t !{task.cpus}

    # Vibrant sometimes doesn't make files in VIBRANT_figures_<base>, this crashes vibrant in batch
    # We should probably patch Vibrant to fix the underlying issue, but this folder is likely unimportant a quick patch
    # will do for now
    if [[ -z "$(ls -A VIBRANT_${base}/VIBRANT_figures_${base})" ]]
    then
        touch VIBRANT_${base}/VIBRANT_figures_${base}/empty.txt
    fi
    '''
}

#!/usr/bin/env nextflow

// Convert a name-sorted paired-end BAM into two FASTQ files
process bam_to_fastq {
    label "process_single"
    container "${params.container__bedtools}"

    input:
        tuple val(sampleid), path(bam_file) // paired-end BAM, must be sorted by name

    output:
        tuple val(sampleid), path("${sampleid}_R1.fastq"), emit: fastq_r1
        tuple val(sampleid), path("${sampleid}_R2.fastq"), emit: fastq_r2

    shell:
    '''
    bedtools bamtofastq -i !{bam_file} -fq !{sampleid}_R1.fastq -fq2 !{sampleid}_R2.fastq
    '''
}

// Pad a region of interest (ROI) with flank lengths, then extract the resulting sequence from a FASTA
process get_fasta {
    label "process_single"
    container "${params.container__bedtools}"

    input:
        path(fasta_file)     // Input FASTA file to be extracted from
        path(region_bed)     // Region identifier of an ROI (e.g. edit region coordinates)
        path(flank_lengths)  // Flank sequence lengths used to pad the ROI

    output:
        path("out.fa"),        emit: roi_sequence  // ROI's genomic sequence (flipped to the forward strand if required)
        path("out_region.bed"), emit: padded_region // ROI coordinates + padding

    shell:
    '''
    chrom=`cut -f 1 !{region_bed}`
    strand=`cut -f 6 !{region_bed}`
    if [[ $strand == '+' ]]
    then
        left_flank=`cut -f 1 !{flank_lengths}`
        right_flank=`cut -f 2 !{flank_lengths}`
    else
        right_flank=`cut -f 1 !{flank_lengths}`
        left_flank=`cut -f 2 !{flank_lengths}`
    fi
    max_val=`cut -f 3 !{region_bed}`
    max_val=`expr $max_val + $left_flank + $right_flank`
    echo "$chrom\t$max_val" > genome_file.txt
    bedtools slop -i !{region_bed} -g genome_file.txt -l $left_flank -r $right_flank > out_region.bed
    bedtools getfasta -fi !{fasta_file} -bed out_region.bed -fo out.fa
    '''
}

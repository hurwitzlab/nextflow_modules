#!/usr/bin/env nextflow

// Nucleotide BLAST a sample's contigs against a small reference fasta, building the database in place
process blastn_reference_fasta {
    label "process_single"
    container "${params.container__blast}"
    publishDir "${params.blast_outdir}", mode: 'copy'

    input:
        tuple val(sampleid), path(contigs)
        path(reference, stageAs: "blast_db/reference.fasta")

    output:
        tuple val(sampleid), path("${sampleid}_blast_results.tsv"), emit: reference_blast_hits

    shell:
    '''
    # build blast database from the reference fasta
    ( cd blast_db && makeblastdb -in reference.fasta -parse_seqids -blastdb_version 5 -dbtype nucl )

    # column definitions via CLI or http://www.metagenomics.wiki/tools/blast/blastn-output-format-6
    COLUMNS='qseqid sseqid qlen length pident mismatch gapopen qstart qend sstart send evalue bitscore'

    # run blast
    blastn \
    -query !{contigs} \
    -db !{reference} \
    -outfmt "6 $COLUMNS" \
    -out blast_result_no_header.tsv

    # add a header
    echo $COLUMNS | tr ' ' '\t' > !{sampleid}_blast_results.tsv
    cat blast_result_no_header.tsv >> !{sampleid}_blast_results.tsv
    '''
}

// Megablast a sample's contigs against a shared BLAST database, keeping high-identity hits
process megablast_reference_database {
    label "process_high"
    container "${params.container__blast}"
    publishDir "${params.blast_outdir}", mode: 'copy'

    input:
        tuple val(sampleid), path(contigs)
        val(database)
        val(database_name)

    output:
        tuple val(sampleid), path("${sampleid}_megablast_hits.blast"), emit: megablast_hits

    shell:
    '''
    file_handler !{database}

    blastn -task megablast \
           -query !{contigs} \
           -db !{database}/!{database_name} \
           -outfmt '6 qseqid sseqid pident length mismatch gapopen qstart qend sstart send evalue bitscore staxids' \
           -num_threads !{task.cpus} | awk '$3>50 && $4>100' > !{sampleid}_megablast_hits.blast
    '''
}

// All-vs-all pairwise nucleotide BLAST across a directory of reference genomes
process blastn_pairwise_all_vs_all {
    label "process_single"
    container "${params.container__blast}"

    input:
        path(genome_dir)

    output:
        path "blastn_out", emit: pairwise_blast_results

    shell:
    '''
    # blast customized column definitions
    COLUMNS='qseqid sseqid qlen slen length pident mismatch gapopen qstart qend sstart send evalue bitscore'

    mkdir blastn_out

    # get the list of all reference vector genomes in the genome directory
    genomes=( $( ls !{genome_dir} ) )

    # run pairwise blastn on all 2-combination from all reference genomes
    for ((i=0; i < ${#genomes[@]}-1; i++)); do
        for ((j=i+1; j < ${#genomes[@]}; j++)); do
            # run pairwise blastn
            blastn \
            -query "!{genome_dir}/${genomes[i]}" \
            -subject "!{genome_dir}/${genomes[j]}" \
            -outfmt "6 $COLUMNS" \
            -out blast_result_no_header.tsv

            # if blastn output is not empty add header and save in blastn_out dir
            if [[ -s blast_result_no_header.tsv ]]; then
                # extract filenames from the two ref genomes and include in the blast outfile
                outfile="blastn_pairwise.${genomes[i]%.*}.${genomes[j]%.*}.tsv"

                # add the header
                echo $COLUMNS | tr ' ' '\t' > "blastn_out/$outfile"
                cat blast_result_no_header.tsv >> "blastn_out/$outfile"
            fi
        done
    done
    '''
}

// Summarize all-vs-all pairwise BLAST results into a single table
process summarize_blastn_all_pairwise {
    label "process_single"
    container "${params.container__blast}"
    publishDir "${params.blast_outdir}", mode: 'copy'

    input:
        path(blast_dir)

    output:
        path "blast_summary.tsv", emit: pairwise_blast_summary

    shell:
    '''
    vector_comparison_blast_summarize.py \
          --blast_dir !{blast_dir} \
          --out blast_summary.tsv
    '''
}

// Generate dotplots visualizing all-vs-all pairwise BLAST results
process visualize_blastn_all_pairwise {
    label "process_single"
    container "${params.container__blast}"
    publishDir "${params.blast_outdir}", mode: 'copy'

    input:
        path(blast_dir)

    output:
        path "dotplot_dir", emit: pairwise_dotplots

    shell:
    '''
    mkdir dotplot_dir

    for blast_file_path in $( find !{blast_dir} -type f ); do
        blast_file_name="${blast_file_path##*/}"
        dotplot_file_out="${blast_file_name%.*}.svg"
        vector_comparison_blast_dotplot.py \
            --blast_file "$blast_file_path" \
            --out "dotplot_dir/$dotplot_file_out"
    done
    '''
}

// Parse a BLAST XML report into a flat TSV of hits
process parse_blast_xml {
    label "process_medium"
    container "${params.container__blast}"

    input:
        path(mapping_xml)

    output:
        path "mapping_hits.tsv", emit: parsed_hits

    shell:
    '''
    blast_xml_parse.py \
          -i !{mapping_xml} \
          -o mapping_hits.tsv
    '''
}

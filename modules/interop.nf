#!/usr/bin/env nextflow

// Generate Illumina InterOp flowcell-level QC plots and summary tables
process illumina_interop_qc {
    label "process_single"
    container "${params.container__interop}"
    publishDir "${params.interop_outdir}", mode: 'copy'

    input:
        val(flowcell)
        path(xml_inputs), stageAs: 'runDir/'
        path(interop_inputs), stageAs: 'runDir/InterOp/'
        path(bcl_convert_index_hopping), stageAs: 'index_hopping_file.csv'
        path(bcl_convert_unknowns), stageAs: 'bcl_convert_unknowns.csv'
        path(bcl2fastq_unknowns), stageAs: 'bcl2fastq_unknowns.csv'

    output:
        path("out_plot_cycle_Q30Percent.png"), emit: plot_cycle_q30percent
        path("out_plot_cycle_ErrorRate.png"), emit: plot_cycle_errorrate
        path("out_plot_cycle_BasePercent.png"), emit: plot_cycle_basepercent
        path("out_plot_cycle_Intensity.png"), emit: plot_cycle_intensity
        path("out_cycle_Q30Percent.tsv"), emit: cycle_q30percent
        path("out_cycle_ErrorRate.tsv"), emit: cycle_errorrate
        path("out_plot_flowcell_Intensity.png"), emit: plot_flowcell_intensity
        path("out_plot_flowcell_Q30Percent.png"), emit: plot_flowcell_q30percent
        path("out_plot_flowcell_ErrorRate.png"), emit: plot_flowcell_errorrate
        path("out_plot_by_lane.png"), emit: plot_by_lane
        path("out_plot_qscore_heatmap.png"), emit: plot_qscore_heatmap
        path("out_plot_qscore_histogram.png"), emit: plot_qscore_histogram
        path("out_summary.tsv"), emit: summary
        path("out_unknown_barcodes.csv"), emit: unknown_barcodes
        path("out_demux_counts.csv"), emit: demux_counts

    shell:
    '''
    # Some flow_cells might fail at Cluster Generation Stage and prior to Sequencing Stage.
    # This results in some interop plots related to Sequencing Stage fail while the previous stages plots are valid
    # Thus, to have a robust process not complaining on plot missing due to the Cluster Generation fail, an empty plot is first created with `touch`
    # This helps SeqOps to see Cluster level plots for flow_cells

    # cluster stage
    for metric in 'Q30Percent' 'ErrorRate' 'BasePercent' 'Intensity'; do
        fp="out_plot_cycle_${metric}.png"
        touch $fp

        # output the desired columns (1:6) from plot_by_cycle (Cycle, Lower_Limit, P25, P50, P75, Upper_Limit) to  a tsv file
        sp="out_cycle_${metric}.tsv"
        # print the tsv file header
        echo $'Cycle\tLower_limit\tP25\tP50\tP75\tUpper_Limit' > $sp

        # generate both the image plot, fp, and the tsv file, sp.
        # the output of plot_by_cycle is compatible with both TSV (tab separated values) and GNUPlot
        # the below command uses tee and process substitution to output plot_by_cycle to GNUPlot and TSV outputs
        plot_by_cycle runDir/ --metric-name=${metric} | \
        sed "s:^set output.*$:set output '$fp':g" | \
        tee >(gnuplot) | \
        sed -n '/^1/,/e/{'s:,:"\t":g'; /^e/d; p}' | \
        cut -f1-6 >> $sp
    done

    # sequencing stage
    for metric in 'Q30Percent' 'ErrorRate' 'Intensity'; do
        fp="out_plot_flowcell_${metric}.png"
        touch $fp
        plot_flowcell runDir/ --metric-name=${metric} | sed "s:^set output.*$:set output '$fp':g" | gnuplot
    done

    for plot in 'plot_by_lane' 'plot_qscore_heatmap' 'plot_qscore_histogram'; do
        fp="out_${plot}.png"
        touch $fp
        $plot runDir/ | sed "s:^set output.*$:set output '$fp':g" | gnuplot
    done

    # script below extracts the second part of the original format between Total and Scored and then:
    # splits columns with value+/-error into separate columns
    # replaces "," with tab and removes unnecessary empty lines and then
    # adds five columns to the beginning: Flow_Cell, Extracted, Called, Scored, and Read_Level
    # prints the desired format with the new modified headers

    summary runDir/ | sed -n '/Total/,/Scored/{'s:" "::g'; 's:+/-:,:g'; 's:,:"\t":g'; 's:/:"\t":g'; /^Total/d; '/^[[:space:]]*$/d'; p}' | \
        # the format for accessing a NextFlow val parameter in shell section is within this block `!{}`
        awk -v f=!{flowcell} '
            # record the most recent read id as prefix to be added as in new column
            /^Read*/{prefix = $1} \
            # skip lines starting with Lane since they are just needed once for the header
            /^Lane/{next;} \
            # Extract the values for Extracted, Called, and Scored for final output as a new column for each read id
            /^Scored/{split($0,a,":");scored=a[2];next;} \
            /^Called/{split($0,b,":");called=b[2];next;} \
            /^Extracted/{split($0,c,":");extracted=c[2];next;} \
            # keep info line prefixed with read id in an array for final printing
            !/^Read*/{d[i++]=prefix"\t"$0} \
            # print the summary in the desired formatting
            END{print "Flow_Cell\tExtracted\tCalled\tScored\tRead_Level\tLane\tSurface\tTiles\tDensity\tDensity_ERROR\tClusterPF\tClusterPF_ERROR\tLegacyPhasingRate\tLegacyPrephasingRate\tPhasingSlope\tPhasingOffset\tPrephasingSlope\tPrephasingOffset\tReads\tReadsPF\tPercentGreaterEqualQ30\tYield\tCyclesError\tAligned\tAligned_ERROR\tError\tError_ERROR\tError35\tError35_ERROR\tError75\tError75_ERROR\tError100\tError100_ERROR\tPercent_Occupied\tPercent_Occupied_ERROR\tIntensityC1 \tIntensityC1_ERROR";
                for (j=0; j<=i-1;) print f"\t"extracted"\t"called"\t"scored"\t"d[j++]
            }' > out_summary.tsv

    # bcl-convert (NextSeq) reports the top unknown barcodes directly, so just filter the first 6 rows (header + top 5) and extract the two index sequences and count
    if [ -f bcl_convert_unknowns.csv ]; then
        head -n 6 bcl_convert_unknowns.csv | cut -d',' -f2-4 > out_unknown_barcodes.csv
    # bcl2fastq (iSeq, MiniSeq) reports the top unknown barcodes as part of a larger file, so extract that section, get the table header + top 5 rows (skipping the section header), and extract the two index sequences and count
    elif [ -f bcl2fastq_unknowns.csv ]; then
        grep -A 6 "### Most Popular Index Pairs" bcl2fastq_unknowns.csv | tail -n 6 | cut -f1,3,5 --output-delimiter ',' > out_unknown_barcodes.csv
    else touch out_unknown_barcodes.csv
    fi

    # bcl-convert (NextSeq) also prints out a full index hopping count table - follow the analysis from Index_Hopping_Analysis_v1_2.py to compute hopping ratio
    if [ -f index_hopping_file.csv ]; then
        # skip the header
        awk 'NR!=1 {print}' | \
        # if this is an expected pair, add it to the counts table and demux total
        awk -F "," '{ if ($2) { \
            index1_count[$3]+=$5; \
            index2_count[$4]+=$5; \
            demux_total+=$5; \
        } \
        # else compute the hopping ratio and add it to the bad pairs list if above 0.5 percent
        else { \
            index_hop_total+=$5; \
            if (index1_count[$3] != 0 && index2_count[$4] != 0) \
            { \
                ratio_1=$5/index1_count[$3]; \
                ratio_2=$5/index2_count[$4]; \
                hopping_ratio=sqrt(ratio_1*ratio_2); \
                if ( hopping_ratio >= (0.005) ) \
                { \
                    bad_pairs[$3"-"$4]=hopping_ratio; \
                } \
            } \
        } } \
        END {print "Key,Value"; \
             print "DemuxCount,"demux_total; \
             print "IndexHopCount,"index_hop_total; \
             for(key in bad_pairs)
             {
                 print key","bad_pairs[key];
             } }' index_hopping_file.csv > out_demux_counts.csv
    else touch out_demux_counts.csv
    fi
    '''
}

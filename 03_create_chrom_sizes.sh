awk 'BEGIN{OFS="\t"}{print $1, $NF}' restriction_sites/sample_hap1_clean.fasta_Arima.txt > chrom_sizes_sample_hap1


# Inputs
paf_file = "/path/to/final_genome.paf"
output_file = "/path/to/color.links"
sample_id = "sample_hap1"

# Define a simple color palette for n number of chromosomes. Below example for chr 1-14
chrom_colors = {
    "Chromosome_1": "chr1", "Chromosome_2": "chr2", "Chromosome_3": "chr3",
    "Chromosome_4": "chr4", "Chromosome_5": "chr5", "Chromosome_6": "chr6",
    "Chromosome_7": "chr7", "Chromosome_8": "chr8", "Chromosome_9": "chr9",
    "Chromosome_10": "chr10", "Chromosome_11": "chr11", "Chromosome_12": "chr12",
    "Chromosome_13": "chr13", "Chromosome_14": "chr14"
}

with open(paf_file) as f, open(output_file, 'w') as out:
    for line in f:
        fields = line.strip().split('\t')
        if len(fields) < 12:
            continue  # skip malformed lines

        qname = fields[0]
        qstart = int(fields[2])
        qend = int(fields[3])
        tname = fields[5]
        tstart = int(fields[7])
        tend = int(fields[8])

        ref_chr = f"ref_{tname}"
        qry_chr = f"{sample_id}_{qname}"

        # Derive color from reference chromosome name
        base_chr = tname.split()[0]  # get Chromosome_1 etc.
        color = chrom_colors.get(base_chr, "grey")

        out.write(f"{ref_chr} {tstart} {tend} {qry_chr} {qstart} {qend} color={color}\n")


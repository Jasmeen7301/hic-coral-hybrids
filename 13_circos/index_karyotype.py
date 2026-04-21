# Define full paths and labels/colors for reference and samples
ref_fai = "/path/to/final_genome.fasta.fai"
ref_label = "ref"
ref_color = "red"

sample_fai = "/path/to/sample_hap1.fasta.fai"
sample_id = "sample_hap1"
output_file = "/path/to/circos_karyotype.txt"

def parse_fai(fai_path, prefix, label_prefix, color):
    lines = []
    with open(fai_path) as f:
        for i, line in enumerate(f):
            fields = line.strip().split('\t')
            name = fields[0]
            length = fields[1]
            chrom_name = f"{prefix}_{name}"
            label = f"{label_prefix}_{name}"
            lines.append(f"chr - {chrom_name} {label} 0 {length} {color}")
    return lines

ref_karyos = parse_fai(ref_fai, prefix="ref", label_prefix="ref", color="blue")
sample_karyos = parse_fai(sample_fai, prefix=sample_id, label_prefix=sample_id, color="red")

with open(output_file, 'w') as out:
    out.write("\n".join(ref_karyos + sample_karyos) + "\n")


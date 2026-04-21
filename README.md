# hic-coral-hybrids
Chromosome-scale Hi-C assembly and 3D chromatin analysis of hybrid coral genomes — TAD calling, A/B compartments, rearrangement detection
# Hi-C Chromosome-Scale Assembly and 3D Chromatin Analysis — Coral Hybrid Genomes

> MSc Research Project | University of Melbourne | GADI HPC (NCI Australia)

This repository contains the bioinformatics pipeline used for chromosome-length Hi-C assembly, comparative genomics, and 3D chromatin analysis of sperm hybrid coral genomes.

The project investigated genomic signatures, including TAD organisation, A/B chromatin compartments, and large-scale chromosomal rearrangements, underpinning fitness in hybrid corals.

---

## Repository Structure

```
hic-coral-hybrids/
├── README.md                          # This file — full pipeline documentation
├── 01_alignment/
│   └── 01_align_and_filter.sh         # BWA-MEM2 alignment, duplicate marking, quality filtering
├── 02_scaffolding/
│   └── 02_yahs_scaffolding.sh         # YaHS chromosome-scale scaffolding + Juicer hic file generation
├── 03_comparative/
│   └── 03_circos_rearrangements.sh    # Circos chromosomal rearrangement visualisation
├── 04_matrix_processing/
│   └── 04_hic_matrix_processing.sh    # .hic → .cool → .h5 conversion and ICE normalisation
├── 05_tad_calling/
│   └── 05_tad_calling.sh              # TAD calling and boundary strength analysis
├── 06_compartments/
│   └── 06_ab_compartments.sh         # A/B compartment identification and compartment switching
└── envs/
    └── environment.yml                # Conda environment
```

---

## Pipeline Overview

```
Raw Hi-C reads
      │
      ▼
[01] Alignment & filtering     BWA-MEM2 → samblaster → samtools (MAPQ ≥ 10)
      │
      ▼
[02] Contact pair generation   Matlock
      │
      ▼
[03] Chromosome-scale scaffolding   YaHS + Juicer → .hic files
      │
      ▼
[04] Manual curation           Juicebox Assembly Tools (JBAT)
      │
      ▼
[05] Comparative assembly      D-GENIES synteny dot plots → Circos rearrangement plots
      │
      ▼
[06] Matrix processing         .hic → .cool → .h5, ICE normalisation (cooler)
      │
      ├──► TAD calling          hicFindTADs (25 kb, FDR q < 0.05)
      │
      └──► A/B compartments     hicPCA eigenvector decomposition (2.5 Mb)
```

---

## Environment Setup

```bash
# Clone this repository
git clone https://github.com/<jasmeenkaur>/hic-coral-hybrids.git
cd hic-coral-hybrids

# Create conda environment
conda env create -f envs/environment.yml
conda activate hic-pipeline
```

---

## Step-by-Step Pipeline

### Step 01 — Hi-C Read Alignment and Filtering

```bash
# Align Hi-C reads using BWA-MEM2
bwa-mem2 mem -t 16 \
  reference_genome.fa \
  sample_R1.fastq.gz sample_R2.fastq.gz | \
  samblaster --markSplitReads | \
  samtools view -bS -q 10 - | \
  samtools sort -o sample_aligned_filtered.bam

# Index the BAM file
samtools index sample_aligned_filtered.bam

# Generate Hi-C contact pairs using Matlock
matlock bamfilt -i sample_aligned_filtered.bam | \
  samtools view -bS - | \
  matlock bam2 juicer - sample_contacts.txt

sort -k2,2 -k6,6 sample_contacts.txt > sample_contacts_sorted.txt
```

### Step 02 — Chromosome-Scale Scaffolding with YaHS

```bash
# Run YaHS scaffolding
yahs reference_assembly.fa sample_aligned_filtered.bam \
  -o yahs_output/sample_scaffolded

# Generate multi-resolution .hic files using Juicer
# (integrated with YaHS output)
cd yahs_output/
(java -jar juicer_tools.jar pre \
  sample_scaffolded.bin \
  sample_scaffolded.hic \
  sample_scaffolded_assembly) 2>&1 | tee juicer_log.txt
```

### Step 03 — Manual Curation in Juicebox

Manual curation was performed using **Juicebox Assembly Tools (JBAT)**:
1. Load `.assembly` and `.hic` files into JBAT
2. Correct misjoins by identifying off-diagonal signal
3. Confirm chromosomal contiguity through long-range interaction patterns
4. Validate structural changes
5. Export curated assembly as `.fasta`

After curation, regenerate Hi-C contact maps:
```bash
# Generate new contact maps post-curation using 3D-DNA visualisation script
bash /path/to/3d-dna/visualize/run-assembly-visualizer.sh \
  curated_assembly.assembly \
  curated_assembly.fasta
```

### Step 04 — Comparative Assembly (D-GENIES + Circos)

```bash
# Pairwise alignment of each hybrid against reference 2578 using D-GENIES
# (run via D-GENIES web interface or CLI with minimap2 backend)
minimap2 -x asm5 \
  reference_2578.fasta \
  query_hybrid.fasta > alignment.paf

# Generate Circos karyotype files from indexed FASTA
samtools faidx curated_assembly.fasta
awk '{print "chr - "$1" "$1" 0 "$2" chr"NR}' \
  curated_assembly.fasta.fai > karyotype.txt

# Convert PAF to Circos link format
awk '$10 >= 15000 && $NF >= 0.85 {
  print $6" "$8" "$9" "$1" "$3" "$4
}' alignment.paf > circos_links.txt

# Run Circos (see circos.conf for full configuration)
circos -conf circos.conf
```

### Step 05 — Hi-C Matrix Processing and Normalisation

```bash
# Convert .hic to .cool format
hicConvertFormat \
  -m sample.hic \
  --inputFormat hic \
  --outputFormat cool \
  -o sample.cool \
  --resolutions 25000 2500000

# ICE normalisation using cooler
cooler balance sample.cool::resolutions/25000
cooler balance sample.cool::resolutions/2500000

# Convert to .h5 format for HiCExplorer downstream tools
hicConvertFormat \
  -m sample.cool::resolutions/25000 \
  --inputFormat cool \
  --outputFormat h5 \
  -o sample_25kb.h5

hicConvertFormat \
  -m sample.cool::resolutions/2500000 \
  --inputFormat cool \
  --outputFormat h5 \
  -o sample_2500kb.h5
```

### Step 06 — TAD Calling and Boundary Strength Analysis

```bash
# Call TADs using insulation score algorithm with FDR correction
hicFindTADs \
  -m sample_25kb.h5 \
  --outPrefix tads/sample \
  --correctForMultipleTesting fdr \
  --threshold 0.05 \
  --delta 0.01 \
  --step 3 \
  --window 10

# Outputs:
#   tads/sample_domains.bed       — TAD coordinates
#   tads/sample_boundaries.bed    — boundary positions
#   tads/sample_score.bedgraph    — insulation scores

# Calculate boundary strength (|ΔIS|) using R
Rscript scripts/boundary_strength.R \
  --insulation tads/sample_score.bedgraph \
  --boundaries tads/sample_boundaries.bed \
  --output tads/sample_boundary_strength.tsv
```

### Step 07 — A/B Compartment Identification

```bash
# Generate observed/expected contact matrix
hicTransform \
  -m sample_2500kb.h5 \
  --method obs_exp_lieberman \
  -o sample_2500kb_oe.h5

# Principal component analysis for A/B compartments
hicPCA \
  -m sample_2500kb_oe.h5 \
  -o compartments/sample_pc1.bedgraph \
     compartments/sample_pc2.bedgraph \
  --format bedgraph \
  -noe 2

# Orient PC1 by GC content
hicPCA \
  -m sample_2500kb_oe.h5 \
  -o compartments/sample_pc1_gc_oriented.bedgraph \
  --format bedgraph \
  --gcContentFile reference_gc.bedgraph \
  -noe 1

# A compartment = PC1 ≥ 0 (open, gene-rich, transcriptionally active)
# B compartment = PC1 < 0 (closed, heterochromatic, repressed)
```

### Step 08 — Compartment-Boundary Coupling Analysis

```bash
# Assign compartment identity to each TAD using BEDTools
bedtools map \
  -a tads/sample_domains.bed \
  -b compartments/sample_pc1_gc_oriented.bedgraph \
  -c 4 -o mean \
  > tads/sample_tads_with_pc1.bed

# Compartment switching analysis and Pearson correlation
# between |ΔPC1| and |ΔIS| — see R script
Rscript scripts/compartment_boundary_coupling.R \
  --pc1 compartments/sample_pc1_gc_oriented.bedgraph \
  --boundaries tads/sample_boundaries.bed \
  --insulation tads/sample_score.bedgraph \
  --output results/compartment_coupling.tsv

# Z-score enrichment of A↔B switches at TAD boundaries
Rscript scripts/zscore_enrichment.R \
  --switches compartments/sample_ab_switches.bed \
  --boundaries tads/sample_boundaries.bed \
  --output results/zscore_enrichment.tsv
```

---

## Key Tools and Versions

| Tool | Version | Purpose |
|---|---|---|
| BWA-MEM2 | 2.2.1 | Hi-C read alignment |
| samblaster | 0.1.25 | PCR duplicate marking |
| samtools | 1.15 | BAM filtering and indexing |
| Matlock | latest | Hi-C contact pair generation |
| YaHS | latest | Chromosome-scale scaffolding |
| Juicer Tools | latest | .hic file generation |
| Juicebox/JBAT | latest | Manual assembly curation |
| D-GENIES | 1.2.0 | Comparative synteny dot plots |
| 3D-DNA | latest | Contact map visualisation |
| Circos | 0.69 | Chromosomal rearrangement plots |
| HiCExplorer | 3.7 | Matrix processing, TADs, compartments |
| cooler | latest | ICE normalisation |
| BEDTools | 2.30 | Genomic interval operations |

---

## References

- Vasimuddin et al. (2019) — BWA-MEM2
- Faust & Hall (2014) — samblaster
- Li et al. (2009) — samtools
- Zhou et al. (2023) — YaHS
- Durand et al. (2016) — Juicebox
- Cabanettes & Klopp (2018) — D-GENIES
- Dudchenko et al. (2017) — 3D-DNA
- Krzywinski et al. (2009) — Circos
- Wolff et al. (2020) — HiCExplorer
- Abdennur & Mirny (2020) — cooler
- Crane et al. (2015) — Insulation score
- Lieberman-Aiden et al. (2009) — A/B compartments
- Rao et al. (2014) — Hi-C analysis
- Quinlan & Hall (2010) — BEDTools
- Dixon et al. (2012) — TADs
- Rowley & Corces (2018) — Compartment-boundary coupling

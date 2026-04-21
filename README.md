# Hi-C Chromosome-Scale Assembly and 3D Chromatin Analysis — Coral Hybrid Genomes

> MSc Research Project | University of Melbourne | GADI HPC (NCI Australia)
> Project codes: which ever you are using under your main project on server

This repository contains the full bioinformatics pipeline used for chromosome-length Hi-C assembly, comparative genomics, and 3D chromatin analysis of sperm hybrid coral genomes on the GADI HPC system (NCI Australia).

The project investigated genomic signatures — TAD organisation, A/B chromatin compartments, and large-scale chromosomal rearrangements — underpinning thermal tolerance and fitness in hybrid corals. Sample **A** was used as the reference genome for all comparative analyses.

---

## Repository Structure

```
hic-coral-hybrids/
├── README.md
├── 01_index_genome/
│   └── 01_index_genome.pbs              # BWA index reference genome
├── 02_restriction_sites/
│   └── 02_generate_restriction_sites.pbs # Generate Arima restriction sites
├── 03_chrom_sizes/
│   └── 03_create_chrom_sizes.sh          # Create chromosome sizes file
├── 04_split_hic_reads/
│   └── 04_split_hic_reads.pbs            # Split Hi-C reads for parallel processing
├── 05_juicer/
│   └── 05_juicer.pbs                     # Juicer alignment and contact map generation
├── 06_yahs/
│   └── 06_yahs.pbs                       # YaHS chromosome-scale scaffolding
├── 07_juicer_pre/
│   └── 07_juicer_pre.pbs                 # Prepare JBAT input files
├── 08_juicer_tools/
│   └── 08_juicer_tools.pbs               # Generate .hic file for Juicebox
├── 09_manual_curation/
│   └── NOTES.md                          # Manual Juicebox curation (GUI — no script)
├── 10_matrix_processing/
│   └── 10_matrix_processing.pbs          # .hic → .cool → .h5, ICE normalisation
├── 11_tad_calling/
│   └── 11_tad_calling.pbs                # TAD calling with hicFindTADs
├── 12_ab_compartments/
│   └── 12_ab_compartments.pbs            # A/B compartment identification (hicPCA)
└── 13_circos/
    ├── index_karyotype.py                # Generate Circos karyotype file
    ├── colorpaf_link.py                  # Convert PAF to coloured Circos links
    └── NOTES.md                          # Circos workflow notes
```

---

## Pipeline Overview

```
Raw Hi-C reads
      │
      ▼
[01] Index reference genome         BWA index
      │
      ▼
[02] Generate restriction sites     generate_site_positions.py (Arima)
      │
      ▼
[03] Create chromosome sizes        awk from .fai file
      │
      ▼
[04] Split Hi-C reads               split (20M reads per chunk)
      │
      ▼
[05] Juicer alignment               BWA + samtools → merged_nodups.bam
      │
      ▼
[06] YaHS scaffolding               yahs → chromosome-scale assembly
      │
      ▼
[07] Prepare JBAT files             juicer pre → out_JBAT.hic + .assembly
      │
      ▼
[08] Generate .hic for Juicebox     juicer_tools pre → out_JBAT.hic
      │
      ▼
[09] Manual curation (JBAT)         Juicebox GUI — correct misjoins
      │
      ▼
[10] Matrix processing              .hic → .cool → .h5, ICE normalisation
      │
      ├──► [11] TAD calling          hicFindTADs (25 kb, FDR q < 0.05)
      │
      ├──► [12] A/B compartments     hicPCA eigenvector decomposition (2.5 Mb)
      │
      └──► [13] Circos plots         index_karyotype.py + colorpaf_link.py
```

---

## Step Details

### Step 01 — Index Reference Genome
```bash
qsub 01_index_genome/01_index_genome.pbs
```
Creates a soft link to the reference FASTA and indexes it with BWA. Required before Juicer alignment.

**Resources:** 1 CPU · 50 GB · 30 min

---

### Step 02 — Generate Restriction Sites
```bash
qsub 02_restriction_sites/02_generate_restriction_sites.pbs
```
Generates Arima restriction site positions for both haplotypes using `generate_site_positions.py` from the Juicer toolkit.

**Resources:** 1 CPU · 50 GB · 1.5 hr

---

### Step 03 — Create Chromosome Sizes
```bash
bash 03_chrom_sizes/03_create_chrom_sizes.sh
```
Extracts chromosome names and sizes from the restriction sites file using awk. This is a short local command — no PBS needed.

```bash
awk 'BEGIN{OFS="\t"}{print $1, $NF}' \
  restriction_sites/sample_hap1_clean.fasta_Arima.txt \
  > chrom_sizes_sample_hap1
```

---

### Step 04 — Split Hi-C Reads
```bash
qsub 04_split_hic_reads/04_split_hic_reads.pbs
```
Splits paired-end Hi-C reads into chunks of 20 million reads for parallel processing by Juicer.

**Resources:** 1 CPU · 5 GB · 1 hr

---

### Step 05 — Juicer Alignment and Contact Map Generation
```bash
qsub 05_juicer/05_juicer.pbs
```
Runs the full Juicer pipeline: BWA alignment, duplicate removal, and generation of `merged_nodups.bam`. Uses Arima enzyme configuration.

**Resources:** 24 CPUs · 80 GB · 8 hr

---

### Step 06 — YaHS Chromosome-Scale Scaffolding
```bash
qsub 06_yahs/06_yahs.pbs
```
Runs YaHS to scaffold contigs into chromosome-length sequences using Hi-C contact information from the merged BAM file.

**Resources:** 8 CPUs · 190 GB · 2 hr

---

### Step 07 — Prepare Juicebox Input Files
```bash
qsub 07_juicer_pre/07_juicer_pre.pbs
```
Runs `juicer pre` to generate `out_JBAT.hic` and `out_JBAT.liftover.assembly` files for manual curation in Juicebox.

**Resources:** 2 CPUs · 50 GB · 30 min

---

### Step 08 — Generate .hic File with Juicer Tools
```bash
qsub 08_juicer_tools/08_juicer_tools.pbs
```
Generates the final `.hic` contact map file using Juicer Tools for visualisation in Juicebox.

**Resources:** 4 CPUs · 64 GB · 1 hr

---

### Step 09 — Manual Assembly Curation (Juicebox JBAT)

See `09_manual_curation/NOTES.md` for full instructions.

This step is performed manually using the Juicebox Assembly Tools GUI. Misjoins are identified as off-diagonal signal breaks and corrected by dragging chromosome segments. The curated assembly is exported as a `.assembly` file.

---

### Step 10 — Hi-C Matrix Processing and Normalisation
```bash
qsub 10_matrix_processing/10_matrix_processing.pbs
```
Converts `.hic` files to `.cool` and `.h5` formats, then applies ICE normalisation using HiCExplorer and cooler. Two resolutions are generated:
- **25 kb** — for TAD calling
- **2.5 Mb** — for A/B compartment analysis

**Resources:** 8 CPUs · 64 GB · 4 hr

---

### Step 11 — TAD Calling
```bash
qsub 11_tad_calling/11_tad_calling.pbs
```
Calls Topologically Associating Domains (TADs) using the insulation score algorithm with FDR correction (q < 0.05) at 25 kb resolution.

Outputs: `_domains.bed`, `_boundaries.bed`, `_score.bedgraph`

**Resources:** 8 CPUs · 64 GB · 4 hr

---

### Step 12 — A/B Compartment Identification
```bash
qsub 12_ab_compartments/12_ab_compartments.pbs
```
Identifies A/B chromatin compartments via eigenvector decomposition (PC1) of observed/expected contact matrices at 2.5 Mb resolution.

- **A compartment** (PC1 ≥ 0): open chromatin, gene-rich, transcriptionally active
- **B compartment** (PC1 < 0): closed chromatin, heterochromatic, repressed

**Resources:** 8 CPUs · 64 GB · 4 hr

---

### Step 13 — Circos Chromosomal Rearrangement Plots

See `13_circos/NOTES.md` for full workflow.

Python scripts generate karyotype and link files from genome `.fai` index files and D-GENIES PAF alignments. Circos visualises inversions, fissions, and fusions across hybrid genomes relative to reference 2578.

```bash
python 13_circos/index_karyotype.py   # generate karyotype file
python 13_circos/colorpaf_link.py     # generate coloured link file
# then bundle, filter, and run circos — see NOTES.md
```

---

## Key Tools

| Tool | Version | Purpose |
|---|---|---|
| BWA | latest | Reference genome indexing and alignment |
| Juicer | latest | Hi-C alignment pipeline |
| YaHS | latest | Chromosome-scale scaffolding |
| Juicer Tools | 1.9.9 | .hic file generation |
| Juicebox/JBAT | latest | Manual assembly curation (GUI) |
| HiCExplorer | 3.7 | Matrix processing, TAD calling, compartments |
| cooler | latest | ICE normalisation |
| D-GENIES | 1.2.0 | Synteny dot plots (PAF output) |
| Circos | 0.69 | Chromosomal rearrangement plots |
| samtools | latest | BAM sorting and indexing |
| Python | 3.x | Karyotype and link file generation |

---

## HPC Environment (GADI, NCI Australia)

Jobs are submitted using PBS Pro. To submit any step:
```bash
qsub <script>.pbs
```

To check job status:
```bash
qstat -u <username>
```

Conda environments are activated using:
```bash
source /path/to/conda-setup.sh
conda activate <env_name>
```

---

## References

- Li et al. (2009) — samtools
- Zhou et al. (2023) — YaHS
- Durand et al. (2016) — Juicebox/JBAT
- Cabanettes & Klopp (2018) — D-GENIES
- Krzywinski et al. (2009) — Circos
- Wolff et al. (2020) — HiCExplorer
- Abdennur & Mirny (2020) — cooler
- Crane et al. (2015) — Insulation score / TAD calling
- Lieberman-Aiden et al. (2009) — A/B compartments
- Rao et al. (2014) — Hi-C analysis

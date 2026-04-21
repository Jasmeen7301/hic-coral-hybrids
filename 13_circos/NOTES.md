# Step 13 — Chromosomal Rearrangement Visualisation (Circos)

Circos plots were used to visualise large-scale chromosomal rearrangements — inversions, fissions, and fusions — across F1 sperm hybrid genomes relative to reference sample 2578.

## Scripts in this folder

### `index_karyotype.py`
Generates the Circos karyotype file from `.fai` genome index files.
Defines chromosome names, lengths, and colours for the reference and query genomes.

```bash
python index_karyotype.py
# Output: circos_karyotype.txt
```

### `colorpaf_link.py`
Converts a PAF (Pairwise Alignment Format) file from D-GENIES into a Circos link file with chromosome-based colours.

```bash
python colorpaf_link.py
# Output: color_<sample>.links
```

## Workflow

```bash
# 1. Generate karyotype file
python index_karyotype.py

# 2. Generate coloured link file from PAF
python colorpaf_link.py

# 3. Bundle links to reduce noise
bin/bundlelinks \
  -links color_<sample>.links \
  -max_gap 50000 \
  -min_bundle_identity 0.85 \
  -strict > bundled.links

# 4. Filter short alignments (keep >= 15 kb on both ref and query)
awk '{ if (($3 - $2) > 15000 && ($6 - $5) > 15000) print }' \
  bundled.links > filtered.links

# 5. Run Circos
circos -conf circos.conf
```

## Inputs required

- Reference genome `.fai` index (sample 2578)
- Query genome `.fai` index (each hybrid sample)
- PAF file from D-GENIES pairwise alignment

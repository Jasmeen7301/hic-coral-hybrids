#!/bin/bash
# ============================================================
# 06_ab_compartments.sh
# A/B compartment identification via eigenvector decomposition
#
# Usage: bash 06_ab_compartments.sh <sample_name> <matrix_2500kb.h5> <gc_content.bedgraph>
# ============================================================

set -euo pipefail

SAMPLE=$1
MATRIX=$2
GC_FILE=$3

mkdir -p "compartments/${SAMPLE}"

echo "[$(date)] Generating observed/expected matrix for $SAMPLE"

# ── Generate O/E contact matrix ───────────────────────────────────────────────
hicTransform \
  -m "$MATRIX" \
  --method obs_exp_lieberman \
  -o "compartments/${SAMPLE}/${SAMPLE}_oe.h5"

# ── PCA for A/B compartment identification ────────────────────────────────────
echo "[$(date)] Running PCA on O/E matrix"

hicPCA \
  -m "compartments/${SAMPLE}/${SAMPLE}_oe.h5" \
  -o "compartments/${SAMPLE}/${SAMPLE}_pc1.bedgraph" \
     "compartments/${SAMPLE}/${SAMPLE}_pc2.bedgraph" \
  --format bedgraph \
  --gcContentFile "$GC_FILE" \
  -noe 2

# A compartment = PC1 >= 0  (open, gene-rich, transcriptionally active)
# B compartment = PC1 <  0  (closed, heterochromatic, repressed)

# ── Classify bins as A or B ───────────────────────────────────────────────────
echo "[$(date)] Classifying bins into A/B compartments"

awk 'BEGIN{OFS="\t"} NR>1 {
  if ($4 >= 0) type="A"
  else type="B"
  print $1, $2, $3, $4, type
}' "compartments/${SAMPLE}/${SAMPLE}_pc1.bedgraph" \
  > "compartments/${SAMPLE}/${SAMPLE}_compartments.bed"

# ── Identify A↔B compartment switches (3+ consecutive bin changes) ────────────
echo "[$(date)] Identifying compartment switches"

awk 'NR>1 {
  if (prev_type != "" && prev_type != $5) {
    switch_count++
    print prev_chr, prev_start, $3, prev_type"_to_"$5
  }
  prev_chr=$1; prev_start=$2; prev_end=$3; prev_type=$5
}' "compartments/${SAMPLE}/${SAMPLE}_compartments.bed" \
  > "compartments/${SAMPLE}/${SAMPLE}_ab_switches.bed"

N_A=$(awk '$5=="A"' "compartments/${SAMPLE}/${SAMPLE}_compartments.bed" | wc -l)
N_B=$(awk '$5=="B"' "compartments/${SAMPLE}/${SAMPLE}_compartments.bed" | wc -l)
N_SW=$(wc -l < "compartments/${SAMPLE}/${SAMPLE}_ab_switches.bed")

echo ""
echo "Summary for $SAMPLE:"
echo "  A compartment bins: $N_A"
echo "  B compartment bins: $N_B"
echo "  A↔B switches:       $N_SW"
echo ""
echo "Outputs:"
echo "  → compartments/${SAMPLE}/${SAMPLE}_pc1.bedgraph"
echo "  → compartments/${SAMPLE}/${SAMPLE}_compartments.bed"
echo "  → compartments/${SAMPLE}/${SAMPLE}_ab_switches.bed"

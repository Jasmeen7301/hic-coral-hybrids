#!/bin/bash
# ============================================================
# 05_tad_calling.sh
# TAD calling and boundary strength analysis using HiCExplorer
#
# Usage: bash 05_tad_calling.sh <sample_name> <matrix_25kb.h5>
# ============================================================

set -euo pipefail

SAMPLE=$1
MATRIX=$2

mkdir -p "tads/${SAMPLE}"

echo "[$(date)] Calling TADs for $SAMPLE"

# ── TAD calling with insulation score + FDR correction ───────────────────────
hicFindTADs \
  -m "$MATRIX" \
  --outPrefix "tads/${SAMPLE}/${SAMPLE}" \
  --correctForMultipleTesting fdr \
  --threshold 0.05 \
  --delta 0.01 \
  --step 3 \
  --window 10

# Outputs:
#   tads/<sample>/<sample>_domains.bed      — TAD domain coordinates
#   tads/<sample>/<sample>_boundaries.bed   — TAD boundary positions
#   tads/<sample>/<sample>_score.bedgraph   — insulation scores

echo "[$(date)] TAD calling complete."
echo "  → Domains:    tads/${SAMPLE}/${SAMPLE}_domains.bed"
echo "  → Boundaries: tads/${SAMPLE}/${SAMPLE}_boundaries.bed"
echo "  → Insulation: tads/${SAMPLE}/${SAMPLE}_score.bedgraph"

# ── Summary stats ─────────────────────────────────────────────────────────────
N_TADS=$(wc -l < "tads/${SAMPLE}/${SAMPLE}_domains.bed")
N_BOUNDS=$(wc -l < "tads/${SAMPLE}/${SAMPLE}_boundaries.bed")
echo ""
echo "Summary for $SAMPLE:"
echo "  TADs called:       $N_TADS"
echo "  Boundaries called: $N_BOUNDS"

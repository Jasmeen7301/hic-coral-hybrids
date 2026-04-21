#!/bin/bash
# ============================================================
# 04_hic_matrix_processing.sh
# Convert .hic → .cool → .h5 and apply ICE normalisation
#
# Usage: bash 04_hic_matrix_processing.sh <sample_name> <input.hic>
# ============================================================

set -euo pipefail

SAMPLE=$1
HIC_FILE=$2
RES_TAD=25000        # 25 kb for TAD calling
RES_COMP=2500000     # 2.5 Mb for A/B compartments

mkdir -p matrix_output

echo "[$(date)] Converting .hic to .cool for $SAMPLE"

# ── Convert .hic to .cool at both resolutions ─────────────────────────────────
hicConvertFormat \
  -m "$HIC_FILE" \
  --inputFormat hic \
  --outputFormat cool \
  -o "matrix_output/${SAMPLE}.cool" \
  --resolutions "$RES_TAD" "$RES_COMP"

# ── ICE normalisation ─────────────────────────────────────────────────────────
echo "[$(date)] Applying ICE normalisation"

cooler balance "matrix_output/${SAMPLE}.cool::resolutions/${RES_TAD}"
cooler balance "matrix_output/${SAMPLE}.cool::resolutions/${RES_COMP}"

# ── Convert to .h5 for HiCExplorer downstream tools ──────────────────────────
echo "[$(date)] Converting to .h5 format"

hicConvertFormat \
  -m "matrix_output/${SAMPLE}.cool::resolutions/${RES_TAD}" \
  --inputFormat cool \
  --outputFormat h5 \
  -o "matrix_output/${SAMPLE}_${RES_TAD}bp.h5"

hicConvertFormat \
  -m "matrix_output/${SAMPLE}.cool::resolutions/${RES_COMP}" \
  --inputFormat cool \
  --outputFormat h5 \
  -o "matrix_output/${SAMPLE}_${RES_COMP}bp.h5"

echo "[$(date)] Done."
echo "  → TAD resolution (25 kb):        matrix_output/${SAMPLE}_${RES_TAD}bp.h5"
echo "  → Compartment resolution (2.5Mb): matrix_output/${SAMPLE}_${RES_COMP}bp.h5"

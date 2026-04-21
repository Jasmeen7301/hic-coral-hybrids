#!/bin/bash
# ============================================================
# 01_align_and_filter.sh
# Hi-C read alignment, duplicate marking, and quality filtering
#
# Usage: bash 01_align_and_filter.sh <sample_name> <ref_genome> <R1> <R2>
# ============================================================

set -euo pipefail

SAMPLE=$1
REF=$2
R1=$3
R2=$4
THREADS=16
MAPQ=10

echo "[$(date)] Starting alignment for sample: $SAMPLE"

# ── Align with BWA-MEM2, mark duplicates, filter low-quality ─────────────────
bwa-mem2 mem -t "$THREADS" "$REF" "$R1" "$R2" | \
  samblaster --markSplitReads | \
  samtools view -bS -q "$MAPQ" - | \
  samtools sort -@ "$THREADS" -o "${SAMPLE}_aligned_filtered.bam"

# ── Index BAM ─────────────────────────────────────────────────────────────────
samtools index "${SAMPLE}_aligned_filtered.bam"

echo "[$(date)] Alignment stats for $SAMPLE:"
samtools flagstat "${SAMPLE}_aligned_filtered.bam"

# ── Generate Hi-C contact pairs with Matlock ──────────────────────────────────
matlock bamfilt -i "${SAMPLE}_aligned_filtered.bam" | \
  samtools view -bS - | \
  matlock bam2juicer - "${SAMPLE}_contacts.txt"

sort -k2,2 -k6,6 "${SAMPLE}_contacts.txt" > "${SAMPLE}_contacts_sorted.txt"

echo "[$(date)] Done. Output: ${SAMPLE}_contacts_sorted.txt"

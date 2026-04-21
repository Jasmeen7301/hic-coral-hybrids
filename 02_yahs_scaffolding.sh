#!/bin/bash
# ============================================================
# 02_yahs_scaffolding.sh
# Chromosome-scale scaffolding with YaHS + Juicer .hic generation
#
# Usage: bash 02_yahs_scaffolding.sh <sample_name> <assembly.fa> <filtered.bam>
# ============================================================

set -euo pipefail

SAMPLE=$1
ASSEMBLY=$2
BAM=$3
OUTDIR="yahs_output/${SAMPLE}"
JUICER_JAR="/path/to/juicer_tools.jar"

mkdir -p "$OUTDIR"

echo "[$(date)] Running YaHS scaffolding for $SAMPLE"

# ── YaHS chromosome-scale scaffolding ────────────────────────────────────────
yahs "$ASSEMBLY" "$BAM" -o "${OUTDIR}/${SAMPLE}_scaffolded"

# ── Generate multi-resolution .hic file with Juicer ──────────────────────────
cd "$OUTDIR"
echo "[$(date)] Generating .hic file with Juicer"

java -jar "$JUICER_JAR" pre \
  "${SAMPLE}_scaffolded.bin" \
  "${SAMPLE}_scaffolded.hic" \
  "${SAMPLE}_scaffolded_assembly" 2>&1 | tee juicer_log.txt

echo "[$(date)] Done. Outputs in $OUTDIR"
echo "  → ${SAMPLE}_scaffolded.hic"
echo "  → ${SAMPLE}_scaffolded.assembly"
echo "  → ${SAMPLE}_scaffolded_final.fa"
echo ""
echo "Next step: Load .hic and .assembly files into Juicebox (JBAT) for manual curation"

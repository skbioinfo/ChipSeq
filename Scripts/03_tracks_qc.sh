#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

source scripts/00_config.sh

mkdir -p "${OUTDIR}/bigwig" "${OUTDIR}/qc"

command -v bamCoverage >/dev/null
command -v plotFingerprint >/dev/null

# Create bigWigs (CPM)
while IFS=$'\t' read -r sample_id fastq1 fastq2 assay mark condition replicate pair_id; do
  [[ "${sample_id}" == "sample_id" ]] && continue
  bam="${OUTDIR}/bam/${sample_id}.filtered.bam"

  bamCoverage -b "${bam}" \
    -o "${OUTDIR}/bigwig/${sample_id}.CPM.bw" \
    --binSize 10 \
    --normalizeUsing CPM \
    -p "${THREADS}"
done < "${SAMPLES_TSV}"

# Fingerprint plot
BAM_LIST="${OUTDIR}/qc/bam_list.txt"
awk -F'\t' 'NR>1{print "results/bam/"$1".filtered.bam"}' "${SAMPLES_TSV}" > "${BAM_LIST}"

plotFingerprint -b $(cat "${BAM_LIST}") \
  --labels $(awk -F'\t' 'NR>1{print $1}' "${SAMPLES_TSV}" | paste -sd' ' -) \
  -p "${THREADS}" \
  --plotFile "${OUTDIR}/qc/fingerprint.pdf" \
  --outRawCounts "${OUTDIR}/qc/fingerprint.counts.txt"

echo "Done: tracks + QC"


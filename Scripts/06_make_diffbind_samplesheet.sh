#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'
source scripts/00_config.sh

out="results/diffbind_samplesheet.csv"
mkdir -p results
echo "SampleID,Condition,Replicate,Factor,bamReads,bamControl,Peaks,PeakCaller" > "${out}"

while IFS=$'\t' read -r sample_id fastq1 fastq2 assay mark condition replicate pair_id; do
  [[ "${sample_id}" == "sample_id" ]] && continue
  [[ "${assay}" != "ChIP" ]] && continue

  chip_bam="results/bam/${sample_id}.filtered.bam"

  input_sample=$(awk -F'\t' -v pid="${pair_id}" 'NR>1 && $8==pid && $4=="Input"{print $1; exit}' "${SAMPLES_TSV}")
  input_bam="results/bam/${input_sample}.filtered.bam"

  # MACS peak path: find the narrowPeak file
  peak_file=$(find "results/peaks/macs2" -path "*${sample_id}*${condition}*rep${replicate}*" -name "*_peaks.narrowPeak" | head -n 1)

  echo "${sample_id},${condition},${replicate},${mark},${chip_bam},${input_bam},${peak_file},macs" >> "${out}"
done < "${SAMPLES_TSV}"

echo "Wrote: ${out}"


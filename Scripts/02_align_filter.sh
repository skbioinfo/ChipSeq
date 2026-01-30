#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

source scripts/00_config.sh

mkdir -p "${OUTDIR}/bam"

command -v bowtie2 >/dev/null
command -v samtools >/dev/null
command -v bedtools >/dev/null || true

while IFS=$'\t' read -r sample_id fastq1 fastq2 assay mark condition replicate pair_id; do
  [[ "${sample_id}" == "sample_id" ]] && continue

  if [[ "${USE_PE}" -eq 1 ]]; then
    r1="${OUTDIR}/trimmed/${sample_id}_R1.trim.fastq.gz"
    r2="${OUTDIR}/trimmed/${sample_id}_R2.trim.fastq.gz"
    bowtie2 -x "${BOWTIE2_INDEX}" -1 "${r1}" -2 "${r2}" --very-sensitive -p "${THREADS}" \
      | samtools view -bS - \
      | samtools sort -@ "${THREADS}" -o "${OUTDIR}/bam/${sample_id}.sorted.bam"
  else
    fq="${OUTDIR}/trimmed/${sample_id}.trim.fastq.gz"
    bowtie2 -x "${BOWTIE2_INDEX}" -U "${fq}" --very-sensitive -p "${THREADS}" \
      | samtools view -bS - \
      | samtools sort -@ "${THREADS}" -o "${OUTDIR}/bam/${sample_id}.sorted.bam"
  fi

  samtools index "${OUTDIR}/bam/${sample_id}.sorted.bam"

  # Filter MAPQ >= 30 and remove secondary/supplementary/unmapped
  samtools view -@ "${THREADS}" -b -q 30 -F 1804 "${OUTDIR}/bam/${sample_id}.sorted.bam" \
    | samtools sort -@ "${THREADS}" -o "${OUTDIR}/bam/${sample_id}.filtered.bam"

  # Optional blacklist removal
  if [[ -f "${BLACKLIST_BED}" ]]; then
    bedtools intersect -v -abam "${OUTDIR}/bam/${sample_id}.filtered.bam" -b "${BLACKLIST_BED}" \
      > "${OUTDIR}/bam/${sample_id}.filtered.noblacklist.bam"
    mv "${OUTDIR}/bam/${sample_id}.filtered.noblacklist.bam" "${OUTDIR}/bam/${sample_id}.filtered.bam"
  fi

  samtools index "${OUTDIR}/bam/${sample_id}.filtered.bam"

  samtools flagstat "${OUTDIR}/bam/${sample_id}.filtered.bam" > "${OUTDIR}/bam/${sample_id}.flagstat.txt"
done < "${SAMPLES_TSV}"

echo "Done: alignment + filtering"


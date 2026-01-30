#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

source scripts/00_config.sh

mkdir -p "${OUTDIR}/qc/fastqc" "${OUTDIR}/qc/multiqc" "${OUTDIR}/trimmed"

command -v fastqc >/dev/null
command -v multiqc >/dev/null
command -v cutadapt >/dev/null

while IFS=$'\t' read -r sample_id fastq1 fastq2 assay mark condition replicate pair_id; do
  [[ "${sample_id}" == "sample_id" ]] && continue

  fastqc -t "${THREADS}" -o "${OUTDIR}/qc/fastqc" "${fastq1}" ${fastq2:-}

  if [[ "${USE_PE}" -eq 1 ]]; then
    cutadapt -j "${THREADS}" \
      -a "${ADAPTER_FWD}" -A "${ADAPTER_REV}" \
      -q 20,20 --minimum-length 30 \
      -o "${OUTDIR}/trimmed/${sample_id}_R1.trim.fastq.gz" \
      -p "${OUTDIR}/trimmed/${sample_id}_R2.trim.fastq.gz" \
      "${fastq1}" "${fastq2}"
  else
    cutadapt -j "${THREADS}" \
      -a "${ADAPTER_FWD}" \
      -q 20 --minimum-length 30 \
      -o "${OUTDIR}/trimmed/${sample_id}.trim.fastq.gz" \
      "${fastq1}"
  fi
done < "${SAMPLES_TSV}"

multiqc -o "${OUTDIR}/qc/multiqc" "${OUTDIR}/qc/fastqc"
echo "Done: QC + trimming"


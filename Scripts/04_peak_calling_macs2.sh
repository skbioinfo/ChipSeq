#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

source scripts/00_config.sh

mkdir -p "${OUTDIR}/peaks/macs2"

command -v macs2 >/dev/null

while IFS=$'\t' read -r sample_id fastq1 fastq2 assay mark condition replicate pair_id; do
  [[ "${sample_id}" == "sample_id" ]] && continue
  [[ "${assay}" != "ChIP" ]] && continue

  chip_bam="${OUTDIR}/bam/${sample_id}.filtered.bam"

  input_sample=$(awk -F'\t' -v pid="${pair_id}" 'NR>1 && $8==pid && $4=="Input"{print $1; exit}' "${SAMPLES_TSV}")
  [[ -n "${input_sample}" ]] || { echo "Missing Input for ${sample_id} (pair_id=${pair_id})"; exit 1; }
  input_bam="${OUTDIR}/bam/${input_sample}.filtered.bam"

  name="${sample_id}_${mark}_${condition}_rep${replicate}"
  outp="${OUTDIR}/peaks/macs2/${name}"
  mkdir -p "${outp}"

  if [[ "${PEAK_MODE}" == "broad" ]]; then
    macs2 callpeak -t "${chip_bam}" -c "${input_bam}" \
      -f BAM -g "${EFFECTIVE_GSIZE}" \
      --broad --broad-cutoff 0.1 \
      -n "${name}" --outdir "${outp}"
  else
    macs2 callpeak -t "${chip_bam}" -c "${input_bam}" \
      -f BAM -g "${EFFECTIVE_GSIZE}" \
      -q "${QVAL}" \
      --keep-dup all \
      -n "${name}" --outdir "${outp}"
  fi

  if [[ -f "${outp}/${name}_summits.bed" ]]; then
    awk 'BEGIN{OFS="\t"} {if ($5>=10) print $0}' "${outp}/${name}_summits.bed" \
      > "${outp}/${name}_summits.score10.bed"
  fi
done < "${SAMPLES_TSV}"

echo "Done: MACS2 peak calling"


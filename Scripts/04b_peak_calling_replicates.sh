#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'
source scripts/00_config.sh

mkdir -p "${OUTDIR}/peaks/macs2_pooled" "${OUTDIR}/bam/pooled"

command -v samtools >/dev/null
command -v macs2 >/dev/null

# Get unique mark+condition combos for ChIP
combos=$(awk -F'\t' 'NR>1 && $4=="ChIP"{print $5"\t"$6}' "${SAMPLES_TSV}" | sort -u)

while read -r mark condition; do
  [[ -z "${mark}" ]] && continue

  echo "Pooling BAMs for mark=${mark}, condition=${condition}"

  # List ChIP BAMs for this group
  chip_bams=$(awk -F'\t' -v m="${mark}" -v c="${condition}" \
    'NR>1 && $4=="ChIP" && $5==m && $6==c {print "results/bam/"$1".filtered.bam"}' "${SAMPLES_TSV}")

  # List Input BAMs paired to those ChIPs (using pair_id)
  pair_ids=$(awk -F'\t' -v m="${mark}" -v c="${condition}" \
    'NR>1 && $4=="ChIP" && $5==m && $6==c {print $8}' "${SAMPLES_TSV}")

  input_bams=""
  for pid in ${pair_ids}; do
    in_sample=$(awk -F'\t' -v pid="${pid}" 'NR>1 && $8==pid && $4=="Input"{print $1; exit}' "${SAMPLES_TSV}")
    [[ -n "${in_sample}" ]] || { echo "Missing Input for pair_id=${pid}"; exit 1; }
    input_bams="${input_bams} results/bam/${in_sample}.filtered.bam"
  done

  chip_pooled="${OUTDIR}/bam/pooled/${mark}_${condition}.ChIP.pooled.bam"
  input_pooled="${OUTDIR}/bam/pooled/${mark}_${condition}.Input.pooled.bam"

  samtools merge -@ "${THREADS}" -f "${chip_pooled}" ${chip_bams}
  samtools sort -@ "${THREADS}" -o "${chip_pooled%.bam}.sorted.bam" "${chip_pooled}"
  mv "${chip_pooled%.bam}.sorted.bam" "${chip_pooled}"
  samtools index "${chip_pooled}"

  samtools merge -@ "${THREADS}" -f "${input_pooled}" ${input_bams}
  samtools sort -@ "${THREADS}" -o "${input_pooled%.bam}.sorted.bam" "${input_pooled}"
  mv "${input_pooled%.bam}.sorted.bam" "${input_pooled}"
  samtools index "${input_pooled}"

  name="POOLED_${mark}_${condition}"
  outp="${OUTDIR}/peaks/macs2_pooled/${name}"
  mkdir -p "${outp}"

  if [[ "${PEAK_MODE}" == "broad" ]]; then
    macs2 callpeak -t "${chip_pooled}" -c "${input_pooled}" \
      -f BAM -g "${EFFECTIVE_GSIZE}" \
      --broad --broad-cutoff 0.1 \
      -n "${name}" --outdir "${outp}"
  else
    macs2 callpeak -t "${chip_pooled}" -c "${input_pooled}" \
      -f BAM -g "${EFFECTIVE_GSIZE}" \
      -q "${QVAL}" \
      --keep-dup all \
      -n "${name}" --outdir "${outp}"
  fi

done <<< "${combos}"

echo "Done: pooled peak calling"


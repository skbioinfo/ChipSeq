#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'
source scripts/00_config.sh

[[ "${DO_IDR}" -eq 1 ]] || { echo "DO_IDR=0, skipping"; exit 0; }
command -v idr >/dev/null || { echo "idr not found in PATH"; exit 1; }

mkdir -p "${OUTDIR}/peaks/idr"

# For each mark+condition, pick replicate 1 and 2 ChIP peaks and run IDR
combos=$(awk -F'\t' 'NR>1 && $4=="ChIP"{print $5"\t"$6}' "${SAMPLES_TSV}" | sort -u)

while read -r mark condition; do
  [[ -z "${mark}" ]] && continue

  # Get two replicate ChIP sample_ids
  reps=($(awk -F'\t' -v m="${mark}" -v c="${condition}" \
    'NR>1 && $4=="ChIP" && $5==m && $6==c {print $1}' "${SAMPLES_TSV}"))

  if [[ "${#reps[@]}" -lt 2 ]]; then
    echo "Skipping IDR for ${mark}/${condition} (need >=2 ChIP replicates)"
    continue
  fi

  s1="${reps[0]}"
  s2="${reps[1]}"

  # Find their MACS2 peak files
  # This assumes your peak calling script names outputs consistently:
  # results/peaks/macs2/<name>/<name>_peaks.narrowPeak
  p1=$(find "${OUTDIR}/peaks/macs2" -path "*${s1}*${condition}*rep1*" -name "*_peaks.${IDR_PEAK_TYPE}" | head -n 1)
  p2=$(find "${OUTDIR}/peaks/macs2" -path "*${s2}*${condition}*rep2*" -name "*_peaks.${IDR_PEAK_TYPE}" | head -n 1)

  [[ -f "${p1}" && -f "${p2}" ]] || { echo "Missing peak files for ${mark}/${condition}"; continue; }

  out_prefix="${OUTDIR}/peaks/idr/IDR_${mark}_${condition}"
  echo "Running IDR: ${mark}/${condition}"
  idr --samples "${p1}" "${p2}" \
      --input-file-type narrowPeak \
      --rank p.value \
      --output-file "${out_prefix}.idr.txt" \
      --plot \
      --log-output-file "${out_prefix}.idr.log" \
      --idr-threshold "${IDR_THRESH}"

done <<< "${combos}"

echo "Done: IDR peaks"


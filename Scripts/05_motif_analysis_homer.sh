#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

source scripts/00_config.sh

mkdir -p "${OUTDIR}/motifs"
command -v findMotifsGenome.pl >/dev/null || { echo "HOMER not found"; exit 1; }

find "${OUTDIR}/peaks/macs2" -name "*_summits.bed" | while read -r bed; do
  base=$(basename "${bed}" .bed)
  odir="${OUTDIR}/motifs/${base}"
  mkdir -p "${odir}"

  findMotifsGenome.pl "${bed}" "${HOMER_GENOME}" "${odir}" \
    -size "${MOTIF_WINDOW}" \
    -p "${THREADS}"
done

echo "Done: motif analysis (HOMER)"


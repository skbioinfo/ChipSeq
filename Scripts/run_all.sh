#!/usr/bin/env bash
set -euo pipefail

bash scripts/01_qc_trim.sh
bash scripts/02_align_filter.sh
bash scripts/03_tracks_qc.sh
bash scripts/04_peak_calling_macs2.sh

# Replicate-aware pooled peaks
bash scripts/04b_peak_calling_replicates.sh

# IDR reproducible peaks (if DO_IDR=1)
bash scripts/04c_idr.sh

# Motifs
bash scripts/05_motif_analysis_homer.sh

# DiffBind samplesheet for R
bash scripts/06_make_diffbind_samplesheet.sh

echo "All steps completed. Next run DiffBind:"
echo "Rscript r/04_diffbind_differential_binding.R"

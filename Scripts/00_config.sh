#!/usr/bin/env bash
set -euo pipefail

# Threads
THREADS=16

# Data
SAMPLES_TSV="samples.tsv"
OUTDIR="results"

# Single-end or paired-end
USE_PE=0

# Reference / genome
GENOME="hg19"
BOWTIE2_INDEX="/path/to/bowtie2_indexes/hg19/hg19"   # prefix
REF_FASTA="/path/to/hg19.fa"
BLACKLIST_BED="/path/to/hg19-blacklist.v2.bed"       # optional but recommended

# MACS2
EFFECTIVE_GSIZE="2.7e9"     # hg19
PEAK_MODE="narrow"          # narrow|broad
QVAL="0.01"                 # MACS2 q-value cutoff

# Trimming
ADAPTER_FWD="AGATCGGAAGAGCACACGTCTGAACTCCAGTCA"
ADAPTER_REV="AGATCGGAAGAGCGTCGTGTAGGGAAAGAGTGT"

# Motif analysis
HOMER_GENOME="hg19"
MOTIF_WINDOW=200            # bp around summits


# Replicate handling
DO_IDR=1                  # set 1 if you have >=2 ChIP replicates per condition
IDR_THRESH="0.05"

# Peak mode-specific extension
IDR_PEAK_TYPE="narrowPeak"   # narrowPeak (TF) or broadPeak (histone broad; IDR less standard)


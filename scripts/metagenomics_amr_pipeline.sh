#!/usr/bin/env bash

# Metagenomics AMR Analysis Pipeline
# Author: Rida Kazim
#
# Workflow:
# 1. Quality control
# 2. Read preprocessing
# 3. Taxonomic profiling
# 4. AMR gene identification


set -euo pipefail


# -----------------------------
# Input
# -----------------------------

if [ "$#" -lt 2 ]; then
    echo "Usage:"
    echo "bash metagenomics_amr_pipeline.sh sample_R1.fastq.gz sample_R2.fastq.gz"
    exit 1
fi


R1="$1"
R2="$2"

OUTDIR="${3:-metagenomics_results}"
THREADS="${4:-8}"


echo "--------------------------------"
echo "Metagenomics AMR Pipeline"
echo "--------------------------------"

echo "Forward reads: $R1"
echo "Reverse reads: $R2"
echo "Output folder: $OUTDIR"
echo "Threads: $THREADS"


# -----------------------------
# Check input files
# -----------------------------

if [ ! -f "$R1" ]; then
    echo "Error: $R1 not found"
    exit 1
fi


if [ ! -f "$R2" ]; then
    echo "Error: $R2 not found"
    exit 1
fi


# -----------------------------
# Create directories
# -----------------------------

mkdir -p "$OUTDIR/raw_qc"
mkdir -p "$OUTDIR/trimmed"
mkdir -p "$OUTDIR/taxonomy"
mkdir -p "$OUTDIR/amr"


# -----------------------------
# Step 1: Raw quality control
# -----------------------------

echo "Running FastQC..."

fastqc \
"$R1" \
"$R2" \
-t "$THREADS" \
-o "$OUTDIR/raw_qc"


# -----------------------------
# Step 2: Read preprocessing
# -----------------------------

echo "Running fastp..."

fastp \
-i "$R1" \
-I "$R2" \
-o "$OUTDIR/trimmed/clean_R1.fastq.gz" \
-O "$OUTDIR/trimmed/clean_R2.fastq.gz" \
--html "$OUTDIR/trimmed/fastp_report.html" \
--thread "$THREADS"


# -----------------------------
# Step 3: Taxonomic profiling
# -----------------------------

echo "Running Kraken2..."

kraken2 \
--paired \
"$OUTDIR/trimmed/clean_R1.fastq.gz" \
"$OUTDIR/trimmed/clean_R2.fastq.gz" \
--report "$OUTDIR/taxonomy/report.txt" \
--output "$OUTDIR/taxonomy/output.txt"


# -----------------------------
# Step 4: AMR analysis
# -----------------------------

echo "Running AMR identification..."

amrfinder \
--nucleotide "$OUTDIR/taxonomy/output.txt" \
--output "$OUTDIR/amr/amr_results.txt"


echo "--------------------------------"
echo "Pipeline completed successfully"
echo "--------------------------------"

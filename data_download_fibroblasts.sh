#!/usr/bin/env bash

set -u
set -o pipefail

# -----------------------------
# Configuration
# -----------------------------
ACCESSION_FILE="/home/malina/Desktop/fibroblasts_RNA_seq/SRR_Acc_List_2samples.txt"
BASE_DIR="/home/malina/Desktop/fibroblasts_RNA_seq/"
SRA_DIR="${BASE_DIR}/SRA"
FASTQ_DIR="${BASE_DIR}/RNAseq_fastq"
THREADS=4

mkdir -p "$SRA_DIR" "$FASTQ_DIR" || exit 1
LOG_FILE="${FASTQ_DIR}/download.log"

# Log output to both terminal and file
exec > >(tee -a "$LOG_FILE") 2>&1

echo "Started: $(date)"

# -----------------------------
# Check requirements
# -----------------------------
for cmd in prefetch fasterq-dump gzip; do
    if ! command -v "$cmd" >/dev/null 2>&1; then
        echo "ERROR: $cmd is not installed or not in PATH."
        exit 1
    fi
done

if [[ ! -f "$ACCESSION_FILE" ]]; then
    echo "ERROR: Accession list not found: $ACCESSION_FILE"
    exit 1
fi

FAILED=()

# -----------------------------
# Process accessions
# -----------------------------
while IFS= read -r SRR || [[ -n "$SRR" ]]; do

    SRR="${SRR//$'\r'/}"
    [[ -z "$SRR" ]] && continue

    # Ignore comment lines
    [[ "$SRR" == \#* ]] && continue

    # Basic accession validation
    if [[ ! "$SRR" =~ ^SRR[0-9]+$ ]]; then
        echo "Skipping invalid accession: $SRR"
        continue
    fi

    echo
    echo "========================================"
    echo "Processing $SRR"
    echo "========================================"

    # Step 1: Download SRA data
    if ! prefetch "$SRR" --output-directory "$SRA_DIR"; then
        echo "ERROR: prefetch failed for $SRR"
        FAILED+=("$SRR")
        continue
    fi

    SRA_FILE="${SRA_DIR}/${SRR}/${SRR}.sra"

    if [[ ! -s "$SRA_FILE" ]]; then
        echo "ERROR: SRA file missing or empty: $SRA_FILE"
        FAILED+=("$SRR")
        continue
    fi

    # Step 2: Convert SRA to FASTQ
    if ! fasterq-dump "$SRA_FILE" \
        --split-files \
        --threads "$THREADS" \
        --outdir "$FASTQ_DIR"; then

        echo "ERROR: fasterq-dump failed for $SRR"
        FAILED+=("$SRR")
        continue
    fi

    # Step 3: Compress the resulting FASTQ files
    shopt -s nullglob
    FILES=("$FASTQ_DIR/${SRR}"*.fastq)
    shopt -u nullglob

    if [[ ${#FILES[@]} -eq 0 ]]; then
        echo "ERROR: No FASTQ files generated for $SRR"
        FAILED+=("$SRR")
        continue
    fi

    if ! gzip "${FILES[@]}"; then
        echo "ERROR: gzip failed for $SRR"
        FAILED+=("$SRR")
        continue
    fi

    echo "SUCCESS: $SRR completed"

done < "$ACCESSION_FILE"

# -----------------------------
# Final report
# -----------------------------
echo
echo "Finished: $(date)"

if [[ ${#FAILED[@]} -gt 0 ]]; then
    echo "The following accessions failed:"
    printf '  %s\n' "${FAILED[@]}"
    echo "Check the log: $LOG_FILE"
    exit 1
else
    echo "All accessions processed successfully."
fi

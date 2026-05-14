#!/usr/bin/env bash
# About: combine the gvcf of all the samples
#       Make sure you have installed the latest software.
set -euo pipefail

# check software --------------------------------------------------------
command -v gatk >/dev/null 2>&1 || {
    echo "Error: gatk not found"
    exit 1
}

# -----------------------------------------------------------------------

# Variables rquired for processing ---------------------------------------
MEM="120G"                                        		# memory 
REF="data/reference/chromosomes.fasta"          		# reference sequence - must be faidx index
IDIR="data/variant_call"                        		# input dir path
OUTF="data/variant_call/combined_gvcf/combined.g.vcf.gz"        # output file
LOGF="logs/pa_combined.log"                     		# log file name
# ------------------------------------------------------------------------

mkdir -p $(dirname "$OUTF")

shopt -s nullglob

# Build -V arguments for all the samples
VARIANTS=()

for FILE in "$IDIR"/*.g.vcf.gz; do
    VARIANTS+=(-V "$FILE")
done

# check that files are present
if [ ${#VARIANTS[@]} -eq 0 ]; then
    echo "Error: no GVCF files found in $IDIR"
    exit 1
fi

gatk CombineGVCFs --java-options "-Xmx${MEM}" \
    -R "$REF" \
    -O "$OUTF" \
    "${VARIANTS[@]}"

echo "All processing completed"

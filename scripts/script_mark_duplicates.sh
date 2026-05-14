#!/usr/bin/env bash
# About: mark the duplicate - don't remove. SNP caller will auto skip the marked duplicates
#	software: GATK4
#	GATk will used picard for this task
#       Make sure you have installed the latest software.
#       Additionally, I used GNU parallel to run multiple jobs (recommended for large samples) - you can use for loop.
set -euo pipefail

# check software --------------------------------------------------------
command -v gatk >/dev/null 2>&1 || {
    echo "Error: gatk not found"
    exit 1
}

# -----------------------------------------------------------------------

# Variables rquire for processing ---------------------------------------
LIST="data/list_of_samples.txt"                 # sample/accession list - one sample per line
NJOB=35                                         # number of jobs to run in parallel using GNU parallel
IDIR="data/mapped"                              # input dir path
ODIR="data/deduplicate"                         # output directory path
LOGF="logs/pa_dedup.log"                             # log file name

# GNU paralel
export IDIR ODIR 
# ------------------------------------------------------------------------

# Function
func_dedup() {
	
	set -eu
    	local bam=$1                # bam file
    	local out=$2                # output file name
    	local sample=$3             # sample name
    	local path=$(dirname "$out") # path
    
	echo "Deduplicating: $sample"

    	gatk MarkDuplicates \
    		--INPUT "$bam" \
    		--OUTPUT "$out" \
    		--METRICS_FILE "${path}/${sample}_metrics.txt" \
    		--ASSUME_SORTED true \
    		--REMOVE_DUPLICATES false \
    		--TAG_DUPLICATE_SET_MEMBERS true \
    		--VALIDATION_STRINGENCY LENIENT \
    		--CREATE_INDEX true  \
    		--TMP_DIR tmp/ \
    		--MAX_FILE_HANDLES 1000
    
	echo "Dedup successful: $sample"
	echo "Output written as: $out"

}

export -f func_dedup
mkdir -p "$ODIR"

parallel -j "$NJOB" --load 80% --joblog "$LOGF" "func_dedup ${IDIR}/mapped_{1}_sorted.bam ${ODIR}/{1}_dedup.bam {1}" \
	:::: $LIST

wait

echo "All processing completed"

#!/usr/bin/env bash
# About: mapping reads to reference genome using bwa; sorting and indexing using samtools
#       Make sure you have installed the latest software.
#       Additionally, I used GNU parallel to run multiple jobs (recommended for large samples) - you can use for loop.

set -euo pipefail

# check software --------------------------------------------------------
command -v bwa >/dev/null 2>&1 || {
    echo "Error: bwa not found"
    exit 1
}

# -----------------------------------------------------------------------

# Variables rquire for processing ---------------------------------------
LIST="data/list_of_samples.txt"                 # sample/accession list - one sample per line
NJOB=35                                         # number of jobs to run in parallel using GNU parallel
THREADS=7					# Number of threads
MEM="4G"					# memory to use in samtools sorting
REF="data/reference/chromosomes.fasta"		# must be bwa index
IDIR="data/trimmed"                             # input dir path
ODIR="data/mapped"                              # output directory path
LOGF="logs/pa_bwa.log"                               # log file name

# Filtered FASTQ filenames are assumed to begin with the sample name or accession ID, for example: sample_R1_filtered.fastq.gz, HD38_L003_R2_001_filtered.fastq.gz
SUFX1="_R1_filtered.fastq.gz"                            # Portion or suffix of the filename that follows the sample name
SUFX2="_R2_filtered.fastq.gz"                            # Portion or suffix of the file name that follows the sample name

# GNU paralel
export REF IDIR ODIR SUFX1 SUFX2 THREADS MEM
# ------------------------------------------------------------------------

func_map_sort() {

    set -euo pipefail

    local read1=$1		# read1 path - filtered;
    local read2=$2		# read2 path - filtered
    local reference=$3		# reference - bwa index
    local odir=$4		# output directory
    local sample=$5		# sample name
    local threads=$6
    local memory=$7		# Memory

    # read group - important for gatk!
    local rgroup="@RG\tID:${sample}\tSM:${sample}\tPL:ILLUMINA\tLB:${sample}_lib\tPU:${sample}_unit"	
    echo "Mapping and sorting : $sample"

    bwa mem "$reference" -M \
	    -R "$rgroup" \
	    -t "$threads" "$read1" "$read2" \
	    2> "${odir}/bwa_${sample}.log" \
    | samtools sort -@ "$threads" \
	    -m "$memory" \
	    -o "${odir}/mapped_${sample}_sorted.bam" \
	    2> "${odir}/samtools_sort_${sample}.log"

    echo "Mapping and sorting successful: $sample"

    echo "Indexing BAM: $sample"
    samtools index "${odir}/mapped_${sample}_sorted.bam"
    
}

# Make sure that the reference is bwa indexed
REQUIRED_EXT=(amb ann bwt pac sa)
for EXT in "${REQUIRED_EXT[@]}"; do
	[ -f "${REF}.${EXT}" ] || MISSING=1
done

if [ "${MISSING:-0}" -eq 1 ]; then
	echo "Indexing the reference genome....."
	bwa index "$REF"
	echo "Indexing successful"
fi


# Mapped
export -f func_map_sort

parallel -j "$NJOB" --load 80% --joblog i"$LOGF" "func_map_sort ${IDIR}/{1}${SUFX1} ${IDIR}/{1}${SUFX2} $REF ${ODIR} {1} $THREADS $MEM" \
	:::: "$LIST"


wait

echo "All processing completed"

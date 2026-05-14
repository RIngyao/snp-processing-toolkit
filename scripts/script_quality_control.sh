#!/usr/bin/env bash
# About: quality control using fastp and derived summary using multiqc.
#	Make sure you have installed these two softwares.
#	Additionally, I used GNU parallel to run multiple jobs (recommended for large samples) - you can use for loop.

set -euo pipefail

# check software --------------------------------------------------------
command -v fastp >/dev/null 2>&1 || {
    echo "Error: fastp not found"
    exit 1
}

command -v multiqc >/dev/null 2>&1 || {
    echo "Error: multiqc not found"
    exit 1
}

# If GNU parallel is used, instead of for loop
command -v parallel >/dev/null 2>&1 || {
    echo "Error: GNU parallel not found"
    exit 1
}

# -----------------------------------------------------------------------


# Variables rquire for processing --------------------------------------- 
LIST="data/list_of_samples.txt"			# sample/accession list - one sample per line
NJOB=35						# number of jobs to run in parallel using GNU parallel
IDIR="data/raw"					# input dir path and name
ODIR="data/trimmed"				# output directory path and name
LOGF="pa_fastp.log"  				# log file name

# FASTQ filenames are assumed to begin with the sample name or accession ID, for example: sample_R1.fastq.gz, HD38_L003_R2_001.fastq.gz
SUFX1="_R1_fastq.gz"				# Portion or suffix of the filename that follows the sample name, e.g. _R1_fastq.gz of sample23_R1_fastq.gz
SUFX2="_R2_fastq.gz"				# Portion or suffix of the file name that follows the sample name, e.g. _R2.fastq.gz of sample23_R2.fastq.gz

OMULTI="trimmed_multiqc_report"			# file name of the multiqc report

# GNU parallel - require
export SUFX1 SUFX2 ODIR IDIR
# ------------------------------------------------------------------------

func_trim(){

	set -eu

        local sample=$1         # sample name to process
	local r1=$2		# forward / read1 file name - sample_R1.fastq.gz
	local r2=$3		# reverse / read2 file name - sample_R2_fastq.gz
        local dir=$4            # directory for storing the trimmed samples
	local idir=$5		# input dir path - where fastq is stored
	local threads=5		# number of threads


	mkdir -p "$dir"

	# output file name - append filtered to the input file name
	or1="$(basename $r1 .fastq.gz)_filtered.fastq.gz"
	or2="$(basename $r2 .fastq.gz)_filtered.fastq.gz"

	echo "Processing: $sample"

        fastp -i "${idir}/${r1}" -I "${idir}/${r2}" \
                -o "${dir}/${or1}" -O "${dir}/${or2}" \
                -q 30 -u 30 -l 50 \
		--detect_adapter_for_pe -p -z 1 \
                --thread $threads \
                --json "${dir}/${sample}_fastp.json" \
		--html "${dir}/${sample}_fastp.html" \
                -R "${dir}/${sample}_fastp_report" > "${dir}/${sample}_report.log" 2>&1

	echo "Success quality control: $sample"

}

# GNU parallel - export the function
export -f func_trim

parallel -j "$NJOB" --joblog "logs/${LOGF}" --load 80% "func_trim {1} {1}${SUFX1} {1}${SUFX2} $ODIR $IDIR" :::: "$LIST"


wait

echo "Checking quality"
multiqc --filename $OMULTI \
        --outdir $ODIR \
        $ODIR


echo "All processing completed"

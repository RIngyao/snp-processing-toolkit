#!/usr/bin/env bash
# About: haplotype calling using gatk4
#	The reference sequence needs to be faidx index and exist sequence dictionary.
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
THREADS=4					# number of threads 
PLOIDY=2					# ploidy level for the species
REF="data/reference/chromosomes.fasta"          # must be faidx index
IDIR="data/deduplicate"                         # input dir path
ODIR="data/variant_call"                        # output directory path
LOGF="logs/pa_hapcall.log"                      # log file name

# GNU paralel
export REF IDIR ODIR THREADS PLOIDY
# ------------------------------------------------------------------------

# Function
func_hapCal() {

	set -eu
        local ref=$1            # reference
        local bam=$2            # input bam file
        local out=$3            # output file path and name
        local sample=$4         # sample name
	local threads=$5	# threads
	local ploidy=$6		# ploidy level

        echo "Processing $sample"
        # run the haplotypecaller
        gatk HaplotypeCaller \
                --reference "$ref" \
                -I "$bam" \
		-ploidy "$ploidy" \
                -ERC GVCF \
                --output "$out" \
                --native-pair-hmm-threads "$threads"


      echo "Haplotype call successful: $sample"

}


# make sure the reference sequence is faidx indexed
if [ ! -f "${REF}.fai" ]; then
	echo "Indexing reference genome..."
	samtools index "$REF":w
fi

# Make sure there is sequence dictionary 
if [ ! -f "${REF%.fa}.dict" ]; then
    echo "Creating reference dictionary"
    gatk CreateSequenceDictionary -R $REF
fi


# Execute the haplotype call 
export -f func_hapCal
mkdir -p "$ODIR"

# Execute the haplotypecaller
parallel -j "$NJOB" --load 80% --joblog "$LOGF" "func_hapCal $REF ${IDIR}/{1}_dedup.bam ${ODIR}/{1}.g.vcf.gz {1} $THREADS $PLOIDY" \
	:::: "$LIST"

wait

echo "All processing completed"


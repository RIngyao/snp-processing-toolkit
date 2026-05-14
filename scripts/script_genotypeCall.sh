#!/usr/bin/env bash
# About: Perform joint genotyping
#       The reference sequence needs to be faidx index and exist sequence dictionary.
#       Make sure you have installed the latest software.
set -euo pipefail

# check software --------------------------------------------------------
command -v gatk >/dev/null 2>&1 || {
    echo "Error: gatk not found"
    exit 1
}
# -----------------------------------------------------------------------

# Variables rquired for processing ---------------------------------------
MEM="170G"                                                      # memory
REF="data/reference/chromosomes.fasta"                          # reference sequence
INF="data/variant_call/combined_gvcf/combined.g.vcf.gz"         # input dir path
OUTF="data/variant_call/combined_gvcf/final_genotype.vcf.gz"	# output file
# ------------------------------------------------------------------------

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


if [ -f "$INF" ]; then
	
	echo "Processing..."
	#run GenotypeGVCFs
	gatk --java-options "-Xmx${MEM}" GenotypeGVCFs \
		-R "$REF" \
		-V "$INF" \
		-O "$OUTF" \
		--max-alternate-alleles 2
	
	echo "Join genotyping completed"

else
	echo "Input not found: $INF"
	exit 1
fi

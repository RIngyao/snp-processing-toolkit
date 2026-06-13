#!/usr/bin/env bash
# About: build database and annotate SNP using snpEff

set -euxo pipefail

# ===================
# check software 
command -v snpEff >/dev/null 2>&1 || {
    echo "Error: snpEff not found"
    exit 1
}
# ===================


# ================================================
# Variables rquire for processing
export IDIR="data/variant_call/filtered"		# input dir
export ODIR="data/annotation"                		# output directory path 
export CONFIG="${ODIR}/snpEff/snpEff.config"		# snpEff config file
export SPECIES="species"					# species name - must match with snpEff config
export THREADS=10                            		# Number of threads
export MEM=5				      		# Memory in Gb
NJOB=2							# Number of jobs
LOGF="logs/pa_ann.log"                  	        # log file name
# ==========================================

# =====================================
# Build database for snpeff
# Run this only once per genome/species

if [ ! -s "${ODIR}/snpEff/data/species/snpEffectPredictor.bin" ]; then

       snpEff build -config "$CONFIG" -v "$SPECIES"

fi

# ======================================


func_ann(){

        local vcf=$1                    # input vcf
        local conf=$2                   # snpeff config path and file
        local out=$3                    # output dir
	local species=$4		# species name 
	local mem=$5
	local thread=$6
        local variant=$7                 # variant name

        echo "Annotating : $variant"

        snpEff -Xmx${mem}G ann "$species" "$vcf" \
                -chr "Chr" \
                -i vcf -o vcf \
                -csvStats "${out}/annotated_${variant}_summary" \
                -config "$conf" \
		| bgzip -@ $thread -c > "${out}/annotated_${variant}.vcf.gz"


        echo "Annotation success: $variant"
}

export -f func_ann

parallel -j $NJOB "func_ann ${IDIR}/final_{1}_biallelic.vcf.gz $CONFIG $ODIR $SPECIES $MEM $THREADS {1}" \
	::: snps indels


echo "All processing completed"

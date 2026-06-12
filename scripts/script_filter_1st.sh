#!/usr/bin/env bash
# About: Filter variants based on depth, quality, stats and type
#	Delete the intermediate data, if necessary. I prefer manually examining the data before deleting.
#	IMPORTANT!
#		Filtering thresholds depend on your data, sequencing quality, organism, ploidy, coverage, and study objectives.
#	
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


# Variables -------------------------------------------------------------
export VCF="data/variant_call/combined_gvcf/final_genotype.vcf.gz"	# input vcf file
export THREADS=12							# threads
export ODIR="data/variant_call/filtered"				# output directory
LOGF="logs/pa_filter1.log"                               		# log file name
# -----------------------------------------------------------------------


# function 
func_filter(){

        local vcf=$1            # input vcf file
        local variant=$2        # type of variant - snps or indels
	local odir=$3		# output dir
        local threads=$4        # thread


        echo "Processing $variant"

        # ============================
        # Site filter based on DP:
        #       avg. minimum DP of 3x and avg. maximum of 30x per sample (min=3xN; max=30xN)
        # ============================

        # count samples
        nsample=$(bcftools query -l "$vcf" | wc -l)
        min=$((3 * nsample))
        max=$((30 * nsample))

        if [ ! -s "${odir}/filter1_site_dp.vcf.gz" ]; then

                echo "Filter1: by DP and QUAL"
                bcftools filter --threads ${threads} \
                        -i "INFO/DP >= $min && INFO/DP <= $max && QUAL >= 30" \
                        -Oz -o "${odir}/filter1_site_dp.vcf.gz" "$vcf"
        fi


        # normalize it


        # =========================
        # filter by types - snp and indels
        # =========================
        if [[ "${variant}" == "indels" ]]; then

                # filter indels greater than 8bp
                echo "Filtering Indels"
                bcftools view --threads ${threads} \
                        -i 'TYPE="indel" && abs(strlen(REF) - strlen(ALT)) <= 8' \
                        -Oz -o "${odir}/filter2_${variant}.vcf.gz" "${odir}/filter1_site_dp.vcf.gz"
        else
                echo "Filterin SNP"
                bcftools view --threads ${threads} \
                        -i 'TYPE="snp"' \
                        -Oz -o "${odir}/filter2_${variant}.vcf.gz" "${odir}/filter1_site_dp.vcf.gz"

        fi




        # ===========================
        # filter by quality and stats
        # ===========================
        echo "Filtering by QD, FS, MQ, ReadPosRankSum, MQRankSum for $variant"

        if [[ "$variant" == "snps" ]]; then
                expr='QD < 2.0 || FS > 60.0 || MQ < 40.0 || ReadPosRankSum < -8.0 || MQRankSum < -12.5'
        elif [[ "$variant" == "indels" ]]; then
                expr='QD < 2.0 || FS > 200.0 || ReadPosRankSum < -20.0'
        fi


        bcftools filter --threads ${threads} \
                -e "$expr" \
                -Oz -o "${odir}/filter3_${variant}.vcf.gz" "${odir}/filter2_${variant}.vcf.gz"

        echo "Completed $variant"

}

export -f func_filter

# execute the function
parallel -j 2 --load 80% --joblog "$LOGF" "func_filter $VCF {1} $ODIR $THREADS" ::: snps indels

wait
echo "Next step: filter based on heterozygosity - 30percent, MAF>= 0.05 and PASS"

echo "All processess completed"


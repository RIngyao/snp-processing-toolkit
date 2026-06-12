#!/usr/bin/env bash
# About: Filter variants based on missing rate (mr), heterozygosity (het), MAF
#       IMPORTANT!
#               Filtering thresholds depend on your data, sequencing quality, organism, ploidy, coverage, and study objectives.
#
set -euo pipefail

# check software --------------------------------------------------------
command -v bcftools >/dev/null 2>&1 || {
    echo "Error: bcftools not found"
    exit 1
}
# -----------------------------------------------------------------------

# Variables -------------------------------------------------------------
export IDIR="data/variant_call/combined_gvcf"      			# input directory
export THREADS=12                                                       # threads
export ODIR="data/variant_call/filtered"                                # output directory
LOGF="logs/pa_filter1.log"                                              # log file name
# -----------------------------------------------------------------------



func_filter2(){                                                                                                                                                                                                     local vcf=$1                            # input vcf file from the first filter - f3_variant.vcf.gz
        local variant=$2                        # type of variant - snps or indels
        local out=$3                            # output dir
        local threads=$4                        # thread

        echo "Processing $variant"

        # ====================================
        # set low-depth genotypes to missing (FMT/DP,3)
        # ====================================
        echo "Setting low-depth genotypes to missing"
        bcftools filter \
                -S . \
                -e 'FMT/DP<3' \
                --threads ${threads} \
                "$vcf" \
                -Oz -o "${out}/${variant}_LowDPToMissing.vcf.gz"

        # ==========================================
        # Estimate heterozygosity, Missing rate, MAF
        # and filtering if it is missing in the vcf file
        # ==========================================
        echo "Calculating heterozygosity"
        bcftools +fill-tags "${out}/${variant}_LowDPToMissing.vcf.gz" \
                -- -t AC_Het,NS,F_MISSING,MAF \
                | bgzip -c -@ ${threads} > "${out}/${variant}_hetero_mis_maf_info.vcf.gz"

        echo "Filtering out heterozygosity > 0.30 & F_MISSING > 0.30"

        bcftools view --threads $threads -i 'AC_Het/NS <= 0.30 && F_MISSING <= 0.30' \
                -Oz -o "${out}/final_${variant}.vcf.gz" "${out}/${variant}_hetero_mis_maf_info.vcf.gz"


        echo "Filtering MAF < 0.05"
        bcftools view --threads $threads -e 'MAF < 0.05' \
                -Oz -o "${out}/final_maf2.5_${variant}.vcf.gz" "${out}/final_${variant}.vcf.gz"

	# ===================================
	# retain only biallelic
	# ===================================
	echo "Filtering biallelic..."
	bcftools view --threads $threads -m2 -M2 \
		-Oz -o "${out}/final_${variant}_biallelic.vcf.gz" \
		"${out}/final_maf2.5_${variant}.vcf.gz"

        # ===================================
        # count - optional
        # ===================================
        echo "Counting $variant"
        bcftools stats --threads $thread \
		"${out}/final_${variant}.vcf.gz" > "${out}/stats_final_${variant}.txt"


        echo "Completed $variant"

}

export -f func_filter2

# execute the function
parallel -j 2 --load 80% --joblog "$LOGF" "func_filter2 ${IDIR}/filter3_{1}.vcf.gz {1} $ODIR $THREADS" \
        ::: snps indels

wait

echo "All processess completed"

echo "Next: annotate the variants"


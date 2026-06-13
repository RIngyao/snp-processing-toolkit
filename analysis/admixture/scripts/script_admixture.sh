#!/usr/bin/env bash
# About: running n independent ADMIXTURE (k) with 50 replicates
#       The input data must be LD pruned


set -euo pipefail

# ----------------------------
# User-configurable settings
# ----------------------------
export DATA="ld_pruned_data/pruned_snps.bed"	# ld pruned snps 
START_K=1					# start k
END_K=15					# end k
REPLICATES=50					# replicates
export THREADS=6				# number of threads
export CV_FOLDS=10					
export OUT_ROOT="results"			# output dir
NJOBS=10                			# Number of concurrent jobs - 6*10 = 60 cpu
LOGF="logs/pa_admix.log"			# log file name
# ----------------------------

func_admix() {

    local k="$1"                # cluster number
    local rep="$2"              # replicates
    local data=$3               # input file - pruned data
    local out_dir=$4            # output directory
    local cv_folds=$5           # CV fold
    local threads=$6		# threads
    local seed=$RANDOM          # random

    # output directory
    run_dir="${out_dir}/K${k}/rep_${rep}"
    mkdir -p "$run_dir"


    # Navigate to the output dir
    pushd "$run_dir"

    echo "[$(date +'%F %T')] Running K=${k} replicate=${rep} seed=${seed}"

    # Run ADMIXTURE inside this directory
    admixture --cv=${cv_folds} --seed ${seed} -j${threads} \
              "${data}" "${k}" > "run_K${k}_rep${rep}.log" 2>&1

    # navigate back
    popd
}

export -f func_admix

for k in $(seq "$START_K" "$END_K"); do

    echo "===== Starting K=${k} ======"

    seq_list=$(seq 1 "$REPLICATES")

    parallel -j "$NJOBS" --load 80% --logfile "$LOGF" "func_admix {1} {2} $DATA $OUT_ROOT $CV_FOLDS $THREADS" \
	    ::: "$k" \
	    ::: "$seq_list"

    echo "===== Finished K=${k} ====="

done

echo "All completed. Results in ${OUT_ROOT}"

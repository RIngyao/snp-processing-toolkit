#!/usr/bin/env bash
# About: check quality of sequenced data

set -eu


fastqc data/raw/*.fastq.gz --outdir data/quality --threads 5

echo "All processes completed"


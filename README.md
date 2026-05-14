# About 

This repository provides simple scripts and utilities for SNP calling, preprocessing, filtering, and annotation workflows commonly used in next-generation sequencing (NGS) analysis. 
The toolkit is intended to simplify variant processing of large samples while maintaining flexibility for custom genomic pipelines and downstream analyses.
It will be particularly useful for users who are new to handling large-scale files and SNP analysis workflows.

## Organisation of directory and file

The structure of directories and files are shown below:

```text

.
├── analysis/
├── data/
│   ├── deduplicate/
│   ├── list_of_samples.txt
│   ├── mapped/
│   ├── quality/
│   ├── raw/
│   ├── reference/
│   ├── trimmed/
│   └── variant_call/
│       └── combined_gvcf/
├── logs/
└── scripts/
    ├── script_check_qc.sh
    ├── script_combine_gvcf.sh
    ├── script_genotypeCall.sh
    ├── script_haplotype_call.sh
    ├── script_mapping.sh
    ├── script_mark_duplicates.sh
    └── script_quality_control.sh


```

## Workflow

Workflow diagram is shown below along with the software and file format.


```text

      Raw data			  | 
         ↓			  | FASTQ
   Quality control		  |
(fastqc,fastp, multiqc)		  |
         ↓			
      Mapping			  |
     (bwa mem)			  |
         ↓			  | SAM/BAM
   MarkDuplicates		  |
   (GATK, Picard)		  |
         ↓			  
  HaplotypeCaller		  |
      (GATK)			  |
         ↓			  | GVCF
   CombineGVCFs			  |
      (GATK)			  |
         ↓			  
   GenotypeGVCFs		  |
      (GATK)			  |
         ↓			  | VCF
     Filtering			  |
    (bcftools)			  |
         ↓
     Analysis			  | CSV,TSV..

```

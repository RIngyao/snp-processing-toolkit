# About 

This repository provides simple scripts and utilities for SNP calling, preprocessing, filtering, and annotation workflows commonly used in next-generation sequencing (NGS) analysis. 
The toolkit is intended to help users understand and simplify variant processing of large samples while maintaining flexibility for custom genomic pipelines and downstream analyses.
It may be particularly useful for users who are new to handling large-scale files and SNP analysis workflows.


## Important!

This workflow is intended as a learning and reference resource. Users are encouraged to understand each analysis step and adapt parameters according to their own data, organism, and study design rather than copying and running the workflow directly.


# Organisation of directory and file

The structure of directories and files are shown below:

```text

.
├── analysis
├── data
│   ├── annotation
│   │   └── snpEff
│   │       ├── data
│   │       │   └── species
│   │       │       ├── cds.fa
│   │       │       ├── genes.gff
│   │       │       ├── protein.fa
│   │       │       └── sequence.fa
│   │       └── snpEff.config
│   ├── deduplicate
│   ├── list_of_samples.txt
│   ├── mapped
│   ├── quality
│   ├── raw
│   ├── reference
│   ├── trimmed
│   └── variant_call
│       ├── combined_gvcf
│       └── filtered
├── logs
├── README.md
└── scripts
    ├── script_annotation_snpeff.sh
    ├── script_check_qc.sh
    ├── script_combine_gvcf.sh
    ├── script_filter_1st.sh
    ├── script_filter_2nd.sh
    ├── script_genotypeCall.sh
    ├── script_haplotype_call.sh
    ├── script_mapping.sh
    ├── script_mark_duplicates.sh
    └── script_quality_control.sh


```

# Workflow

Workflow diagram is shown below along with the software and file format.


```text

      Raw data			      | 
         ↓			          | FASTQ
   Quality control		      |
(fastqc,fastp, multiqc)		  |
         ↓			
      Mapping			      |
     (bwa mem)			      |
         ↓			          | SAM/BAM
   MarkDuplicates		      |
   (GATK, Picard)	    	  |
         ↓			  
  HaplotypeCaller	    	  |
      (GATK)		    	  |
         ↓			          | GVCF
   CombineGVCFs    			  |
      (GATK)	    		  |
         ↓			  
   GenotypeGVCFs    		  |
      (GATK)	    		  |
         ↓		        	  |
     Filtering    			  |
    (bcftools)	    		  | VCF
         ↓                    |
      Annotate                |
      (snpEff)	    		  |
         ↓
     Analysis	    		  | CSV,TSV..

```


# NOTE

1. Users should set the appropriate ploidy level for their organism or study design. Ploidy is defined during `HaplotypeCaller` and is carried forward into `GenotypeGVCFs`.


2. Users are encouraged to carefully review the documentation of each software and adjust parameters as needed rather than blindly following the workflow. The parameters used in this pipeline were selected based on the requirements of my own analysis.



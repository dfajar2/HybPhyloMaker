# HybPhyloMaker
   
Set of bash scripts for analysis of HybSeq raw data. Consists of several steps:   
  

0: Download FASTQ files from Illumina BaseSpace storage  
1: Processing raw reads (PhiX removal, adaptor removal, quality filtering, summary statistics)  
2: Mapping reads to reference (using Bowtie), create consensus sequence  
3: Recognize sequences matching probes (generate PSLX files using BLAT)  
4: Create alignments for all genes  
5: Treat missing data, select best genes  
6: Generate FastTree or RAxML gene trees + trees-alignment properties  
7: Root gene trees with outgroup, combine gene trees into a single file  
8: Estimate species tree (ASTRAL, ASTRID, MRL, concatenation)  
9: Subselect suitable genes and repeat steps 7+8 
  
Uses many additional software that must be installed and put in the PATH prior to run scripts (see Table located in docs folder and consider to run install_software.sh).  
Also utilizes many scripts developed by others (located in HybSeqSource folder). PLEASE CITE APPROPRIATELY THOSE SCRIPTS WHEN USING HybPhyloMaker!  

Read manual located in docs folder before running HybPhyloMaker.  


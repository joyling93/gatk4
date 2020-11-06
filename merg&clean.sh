#!/bin/bash
sample_array=('S-KO-AAGCATCG-CATCTACG')
for sample in sample_array
do
	pear -f "Rawdata/${sample}_L1_1.fq.gz" -r "Rawdata/${sample}_L1_2.fq.gz" -o "clean_data/${sample}"
	trim_galore -q 20 --phred33 --stringency 3 --length 19 -e 0.1 "clean_data/${sample}.assembled.fastq" \
	--gzip -o "clean_data"
done
#!/bin/bash
sample_array=('S-KO-AAGCATCG-CATCTACG')
for sample in "${sample_array[@]}"
do
	bwa mem -t 30 -R "@RG\tID:${sample}\tPL:illumina\tSM:${sample}" \
	/data/xzm/ref/gatk4/hg38/hg38 "../clean_data/${sample}.assembled_trimmed.fq.gz" \
	| samtools view -Sb - > "../output/${sample}.bam"
	samtools sort -@ 20 -O bam -o "../output/${sample}.sorted.bam" "../output/${sample}.bam"
	samtools index "../output/${sample}.sorted.bam"
done

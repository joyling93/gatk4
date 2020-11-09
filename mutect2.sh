#!/bin/bash
sample_array=('S-NC-TCAGCCTT-GCATACAG' 'S-KO-AAGCATCG-CATCTACG')
input_dir='../output'
output_dir='../output'
ref_dir="/data/xzm/ref/gatk4/hg38"
tumor_sample_name='S-KO-AAGCATCG-CATCTACG'
normal_sample_name='S-NC-TCAGCCTT-GCATACAG'

for sample in sample_array
do
	#BQSR --known-sites 不用绝对路径会神奇报错
	time gatk BaseRecalibrator -R "${ref_dir}/Homo_sapiens_assembly38.fasta" -I "${input_dir}/${sample}.sorted.bam" \
	--known-sites "${ref_dir}/dbsnp_138.hg38.vcf.gz" --known-sites "${ref_dir}/Mills_and_1000G_gold_standard.indels.hg38.vcf.gz" --known-sites "${ref_dir}/1000G_phase1.snps.high_confidence.hg38.vcf.gz" \
	-O "${output_dir}/recal_data_${sample}.table"

	time gatk ApplyBQSR --bqsr-recal-file "${output_dir}/recal_data_${sample}.table" -R "${ref_dir}/Homo_sapiens_assembly38.fasta" -I "${input_dir}/${sample}.sorted.bam" -O "${output_dir}/${sample}.sorted.BQSR.bam"
done

	#一般会在此步骤之前利用正常样本数据建立PON（相当于参照），并引入突变数据库进行校正，此流程仅用于特殊样本（如特定PCR产物建库）情况
	gatk Mutect2 \
     -R ${ref_dir}/Homo_sapiens_assembly38.fasta \
     -I  ${input_dir}/${tumor_sample_name}.sorted.BQSR.bam \
     -I  ${input_dir}/${normal_sample_name}.sorted.BQSR.bam \
     -tumor ${tumor_sample_name} \
     -normal ${normal_sample_name} \
     -O ${output_dir}/${tumor_sample_name}.mutect2.vcf

     #以下目前需要activate base环境2020.11.09
     vcftools --remove-filtered-all --vcf ${output_dir}/${tumor_sample_name}.mutect2.vcf\
     --recode --stdout | bgzip -f > ${output_dir}/${tumor_sample_name}.mutect2.PASS_ONLY.vcf.gz

     tabix -p vcf ${output_dir}/${tumor_sample_name}.mutect2.PASS_ONLY.vcf.gz
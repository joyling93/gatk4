#!/bin/bash
sample='K'
#BQSR --known-sites 不用绝对路径会神奇报错
time gatk BaseRecalibrator -R "/data/xzm/ref/gatk4/hg38/Homo_sapiens_assembly38.fasta" -I "./20201030/output/${sample}.sorted.markdup.bam" --known-sites "/data/xzm/ref/gatk4/hg38/dbsnp_138.hg38.vcf.gz" --known-sites "/data/xzm/ref/gatk4/hg38/Mills_and_1000G_gold_standard.indels.hg38.vcf.gz" --known-sites "/data/xzm/ref/gatk4/hg38/1000G_phase1.snps.high_confidence.hg38.vcf.gz" -O "./20201030/output/recal_data_${sample}.table"

time gatk ApplyBQSR --bqsr-recal-file "./20201030/output/recal_data_${sample}.table" -R "/data/xzm/ref/gatk4/hg38/Homo_sapiens_assembly38.fasta" -I "./20201030/output/${sample}.sorted.markdup.bam" -O "./20201030/output/${sample}.sorted.markdup.BQSR.bam"

gatk HaplotypeCaller -R "/data/xzm/ref/gatk4/hg38/Homo_sapiens_assembly38.fasta" --emit-ref-confidence GVCF -I "./20201030/output/${sample}.sorted.markdup.BQSR.bam" -O "./20201030/output/${sample}.g.vcf"  #生成gvcf 3h 20%

gatk GenotypeGVCFs -R "/data/xzm/ref/gatk4/hg38/Homo_sapiens_assembly38.fasta" -V "./20201030/output/${sample}.g.vcf" -O "./20201030/output/${sample}.vcf"  #检测变异

#VQSR snp calling
time gatk VariantRecalibrator -R "/data/xzm/ref/gatk4/hg38/Homo_sapiens_assembly38.fasta" -V "./20201030/output/${sample}.vcf" \
-resource:hapmap,known=false,training=true,truth=true,prior=15.0 "/data/xzm/ref/gatk4/hg38/hapmap_3.3.hg38.vcf.gz" \
-resource:omini,known=false,training=true,truth=false,prior=12.0 /data/xzm/ref/gatk4/hg38/1000G_omni2.5.hg38.vcf.gz \
-resource:1000G,known=false,training=true,truth=false,prior=10.0 /data/xzm/ref/gatk4/hg38/1000G_phase1.snps.high_confidence.hg38.vcf.gz \
-resource:dbsnp,known=true,training=false,truth=false,prior=2.0 /data/xzm/ref/gatk4/hg38/dbsnp_138.hg38.vcf.gz \
-an DP -an QD -an FS -an SOR -an ReadPosRankSum -an MQRankSum -mode SNP -tranche 100.0 \
-tranche 99.9 -tranche 99.0 -tranche 95.0 -tranche 90.0 \
-O "./20201030/output/${sample}.snp.recal" \
--tranches-file "./20201030/output/${sample}.snp.tranches" 

time gatk ApplyVQSR -R "/data/xzm/ref/gatk4/hg38/Homo_sapiens_assembly38.fasta" -V "./20201030/output/${sample}.vcf" \
--ts-filter-level 99.0 --tranches-file "./20201030/output/${sample}.snp.tranches"  \
--recal-file "./20201030/output/${sample}.snp.recal" \
-mode SNP \
-O ./20201030/output/${sample}.snps.VQSR.vcf.gz

#VQSR indel calling
$time gatk VariantRecalibrator -R "/data/xzm/ref/gatk4/hg38/Homo_sapiens_assembly38.fasta" -V "./20201030/output/${sample}.vcf" \
-resource:mills,known=true,training=true,truth=true,prior=12.0 "/data/xzm/ref/gatk4/hg38/Mills_and_1000G_gold_standard.indels.hg38.vcf.gz" \
-an DP -an QD -an FS -an SOR -an ReadPosRankSum -an MQRankSum \
-mode INDEL --max-gaussians 6 \
--tranches-file "./20201030/output/${sample}.snp.indel.tranches" \
-O ./20201030/output/${sample}.snp.indel.recal

time gatk ApplyVQSR -R "/data/xzm/ref/gatk4/hg38/Homo_sapiens_assembly38.fasta" -V ./20201030/output/${sample}.snps.VQSR.vcf.gz \
--ts-filter-level 99.0 \
--tranches-file "./20201030/output/${sample}.snp.indel.tranches" --recal-file "./20201030/output/${sample}.snp.indel.recal" \
-mode INDEL \
-O ./20201030/output/${sample}.VQSR.vcf.gz
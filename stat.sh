#!bin bash
#samples=()
for sample in "$@"
do
	echo "${sample}:\n"
	vcftools --gzvcf "${sample}" --depth --stdout
	vcftools --gzvcf "${sample}" --TsTv-summary --stdout
done
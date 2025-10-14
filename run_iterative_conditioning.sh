dx build -f iterative-conditioning

input="plink"

for p in 0.01 0.001 0.0001; do
    for anc in eur; do
        for chr in 1 2; do
            echo "${chr}..."
            anc_upper=$(echo "$anc" | awk '{print toupper($0)}')
            # DIRs
            model_dir="Isaac/common_condition/"
            variance_dir="Isaac/common_condition/"
            group_dir="/brava/inputs/annotations/v7/"
            # gene_trait_pairs="/Isaac/common_condition/gene_phenotype_pairs_290525.csv"
            gene_trait_pairs="/Isaac/common_condition/new_october_gene_phenotype_pairs.csv"

            if [ ! -f "json/file_paths_${anc}_chr${chr}.json" ]; then
                
                # Create an input .json file for the long and horrible array variables

                # MODEL_DIR
                dx ls ${model_dir} | awk -v anc="${anc_upper}" -v dir="${model_dir}" '$1 ~ ("_" anc ".*\\.rda$") {print dir $1}' | \
                while read f; do
                    echo "{\"\$dnanexus_link\":{\"project\":\"$(dx describe $f --json | jq -r .project)\",\"id\":\"$(dx describe $f --json | jq -r .id)\"}}"
                done | jq -s '{MODEL_DIR: .}' > model_dir.json
                    
                # VARIANCE_DIR
                dx ls ${variance_dir} | awk -v anc="$anc_upper" -v dir="${variance_dir}" '$1 ~ ("_" anc ".*\\.txt$") {print dir $1}' | \
                while read f; do
                    echo "{\"\$dnanexus_link\":{\"project\":\"$(dx describe $f --json | jq -r .project)\",\"id\":\"$(dx describe $f --json | jq -r .id)\"}}"
                done | jq -s '{VARIANCE_DIR: .}' > variance_dir.json
                
                # GROUP_DIR
                dx ls ${group_dir} | awk -v chr="$chr" -v dir="${group_dir}" '$1 ~ ("\\.chr" chr "\\.saige.txt.gz") {print dir $1}' | \
                while read f; do
                    echo "{\"\$dnanexus_link\":{\"project\":\"$(dx describe $f --json | jq -r .project)\",\"id\":\"$(dx describe $f --json | jq -r .id)\"}}"
                done | jq -s '{GROUP_DIR: .}' > group_dir.json

                jq -s 'add' <(cat model_dir.json) <(cat variance_dir.json) <(cat group_dir.json) > json/file_paths_${anc}_chr${chr}.json
            
            fi

            if [ "${input}" = "vcf" ]; then
                echo ${input}
                dx run iterative-conditioning \
                        -i VCF="/Isaac/static_qc_vcf/UKB.chr${chr}.full_qc.exome.${anc_upper}.convert.vcf.gz" \
                        -i VCF_CSI="/Isaac/static_qc_vcf/UKB.chr${chr}.full_qc.exome.${anc_upper}.convert.vcf.gz.csi" \
                        -i SPARSE_MATRIX="/brava/inputs/GRM_autosomes/brava_${anc_upper}_relatednessCutoff_0.05_5000_randomMarkersUsed.sparseGRM.mtx" \
                        -i SPARSE_MATRIX_IDs="/brava/inputs/GRM_autosomes/brava_${anc_upper}_relatednessCutoff_0.05_5000_randomMarkersUsed.sparseGRM.mtx.sampleIDs.txt" \
                        -i GENE_TRAIT_PAIRS_TO_TEST=${gene_trait_pairs} \
                        -f json/file_paths_${anc}_chr${chr}.json \
                        -i ANC=${anc} \
                        -i CHR=${chr} \
                        -i P_T=${p} \
                        --instance-type "mem2_ssd1_v2_x4" --priority high \
                        --destination /brava/duncan/outputs/iterative-conditioning-vcf/${anc_upper}_${p}/ -y \
                        --name "iterative_conditioning_${anc}_${chr}"
            else
                echo ${input}
                dx run iterative-conditioning \
                        -i PLINK_BIM="/Barney/wes/sample_filtered/ukb_wes_450k.qced.chr${chr}.bim" \
                        -i PLINK_BED="/Barney/wes/sample_filtered/ukb_wes_450k.qced.chr${chr}.bed" \
                        -i PLINK_FAM="/Barney/wes/sample_filtered/ukb_wes_450k.qced.chr${chr}.fam" \
                        -i SPARSE_MATRIX="/brava/inputs/GRM_autosomes/brava_${anc_upper}_relatednessCutoff_0.05_5000_randomMarkersUsed.sparseGRM.mtx" \
                        -i SPARSE_MATRIX_IDs="/brava/inputs/GRM_autosomes/brava_${anc_upper}_relatednessCutoff_0.05_5000_randomMarkersUsed.sparseGRM.mtx.sampleIDs.txt" \
                        -i GENE_TRAIT_PAIRS_TO_TEST=${gene_trait_pairs} \
                        -f json/file_paths_${anc}_chr${chr}.json \
                        -i ANC=${anc} \
                        -i CHR=${chr} \
                        -i P_T=${p} \
                        --instance-type "mem2_ssd2_v2_x8" --priority high \
                        --destination /brava/duncan/outputs/iterative-conditioning-plink/${anc_upper}_${p}/ -y \
                        --name "iterative_conditioning_${anc}_${chr}"
            fi
        done
    done
done

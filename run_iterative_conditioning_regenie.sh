dx build -f iterative-conditioning-regenie

input="plink"

for p in 0.00001; do
    for anc in eur; do
        for chr in X; do
            echo "${chr}..."
            anc_upper=$(echo "$anc" | awk '{print toupper($0)}')
            # DIRs
            loco_dir="/nbaya/regenie/data/step1/EUR/"
            annotation_dir="/nbaya/regenie/data/annotations/v7/"
            gene_trait_pairs="/Isaac/common_condition/gene_phenotype_pairs_051125.csv"

            if [ ! -f "json/file_paths_${anc}_chr${chr}_regenie.json" ]; then
                
                # Create an input .json file for the long and horrible array variables
                # TEST: for just Height

                # MODEL_DIR
                dx ls ${loco_dir} | awk -v anc="${anc_upper}" -v dir="${loco_dir}" '$1 ~ ("_" anc "_Height.*\\.loco$") {print dir $1}' | \
                while read f; do
                    echo "{\"\$dnanexus_link\":{\"project\":\"$(dx describe $f --json | jq -r .project)\",\"id\":\"$(dx describe $f --json | jq -r .id)\"}}"
                done | jq -s '{LOCO_DIR: .}' > loco_dir.json
                    
                # ANNOT_DIR
                dx ls ${annotation_dir} | awk -v dir="${annotation_dir}" '$1 ~ ("regenie_.*\\.v7\\..*txt$") {print dir $1}' | \
                while read f; do
                    echo "{\"\$dnanexus_link\":{\"project\":\"$(dx describe $f --json | jq -r .project)\",\"id\":\"$(dx describe $f --json | jq -r .id)\"}}"
                done | jq -s '{ANNOTATION_DIR: .}' > annotation_dir.json

                jq -s 'add' <(cat loco_dir.json) <(cat annotation_dir.json) > json/file_paths_${anc}_chr${chr}_regenie.json
            
            fi

            echo ${input}
            dx run iterative-conditioning-regenie \
                    -i PLINK_BIM="/Barney/wes/sample_filtered/ukb_wes_450k.qced.chr${chr}.bim" \
                    -i PLINK_BED="/Barney/wes/sample_filtered/ukb_wes_450k.qced.chr${chr}.bed" \
                    -i PLINK_FAM="/Barney/wes/sample_filtered/ukb_wes_450k.qced.chr${chr}.fam" \
                    -i KEEP="/nbaya/regenie/data/genotypes/ukb22418_b0_v2.autosomes.qced.${anc_upper}.id" \
                    -i PHENOTYPES="/nbaya/regenie/data/phenotypes/ukb.standing_height.20250508.tsv.gz" \
                    -i COVARIATES="/nbaya/regenie/data/phenotypes/ukb_brava_default_covariates.20250508.tsv.gz" \
                    -i GENE_TRAIT_PAIRS_TO_TEST=${gene_trait_pairs} \
                    -f json/file_paths_${anc}_chr${chr}_regenie.json \
                    -i ANC=${anc} \
                    -i CHR=${chr} \
                    -i P_T=${p} \
                    --instance-type "mem2_ssd2_v2_x8" --priority high \
                    --destination /brava/duncan/outputs/iterative-conditioning-regenie-nov25/${anc_upper}_${p}/ -y \
                    --name "iterative_conditioning_regenie_${anc}_${chr}"

        done
    done
done

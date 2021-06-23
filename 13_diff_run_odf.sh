#!/bin/bash

# Load Local Variables
source ./SET_VARIABLES.sh

python3 ${SCRIPTS}/round_bvals.py \
    --in ${DIFF_DATA_NORM_RELEASE_DIR}/data_norm.bval \
    --out ${DIFF_DATA_NORM_RELEASE_DIR}/data_norm_rounded.bval

echo 'Fit CSA odf'
python3 ${SCRIPTS}/fit_csa.py \
    ${DIFF_DATA_NORM_RELEASE_DIR}/data_norm.nii.gz \
    ${DIFF_DATA_NORM_RELEASE_DIR}/data_norm_rounded.bval \
    ${DIFF_DATA_NORM_RELEASE_DIR}/data_norm.bvec \
    ${DIFF_DATA_DIR}/mask.nii.gz \
    ${ODF_DIR}/csa.nii.gz \
    ${N_CORES} 1e-5 0.006 6


echo 'Sharpen odf'
mkdir -p ${ODF_DIR}/sharpen_ratios

for RATIO in ${RATIOS[@]};
do
    echo 'Ratio '${RATIO}
    python3 ${SCRIPTS}/sharpen_sh_parallel.py \
            --in ${ODF_DIR}/csa.nii.gz \
            --out ${ODF_DIR}/sharpen_ratios/csa_sharp_r${RATIO}.nii.gz \
            --mask ${DIFF_DATA_DIR}/mask.nii.gz \
            --ratio ${RATIO} \
            --tau 0.1 --lambda 1. --csa_norm True \
            --cores ${N_CORES}
done


echo 'Extracting Peaks'
mkdir -p ${ODF_DIR}/peaks_ratios

for RATIO in ${RATIOS[@]};
do
    echo 'Extracting peaks from sharpened Ratio '${RATIO}
    python3 ${SCRIPTS}/peak_extraction.py \
            ${ODF_DIR}/sharpen_ratios/csa_sharp_r${RATIO}.nii.gz \
            ${ODF_DIR}/peaks_ratios/nufo_csa_sharp_r${RATIO}.nii.gz \
            ${ODF_DIR}/peaks_ratios/dir_csa_sharp_r${RATIO}.nii.gz \
            ${ODF_DIR}/peaks_ratios/len_csa_sharp_r${RATIO}.nii.gz \
            --relth 0.25 --minsep 25 --maxn 10 \
            --mask ${DIFF_DATA_DIR}/mask.nii.gz

done


echo 'Computing AIC for all peaks approximation'
mkdir -p ${ODF_DIR}/aic_ratios

for RATIO in ${RATIOS[@]};
do
    echo 'AIC from sharpened Ratio '${RATIO}
    python3 ${SCRIPTS}/compute_aic_all_peaks.py \
            --data ${DIFF_DATA_NORM_RELEASE_DIR}/data_norm.nii.gz \
            --bval ${DIFF_DATA_NORM_RELEASE_DIR}/data_norm.bval \
            --bvec ${DIFF_DATA_NORM_RELEASE_DIR}/data_norm.bvec \
            --mask ${DIFF_DATA_DIR}/mask.nii.gz \
            --inufo ${ODF_DIR}/peaks_ratios/nufo_csa_sharp_r${RATIO}.nii.gz \
            --idirs ${ODF_DIR}/peaks_ratios/dir_csa_sharp_r${RATIO}.nii.gz \
            --ilen ${ODF_DIR}/peaks_ratios/len_csa_sharp_r${RATIO}.nii.gz \
            --sigma ${NOISEMAP_DIR}/sigma_norm.nii.gz \
            --ratio ${RATIO} \
            --oaic ${ODF_DIR}/aic_ratios/aic_csa_sharp_r${RATIO}.nii.gz \
            --cores ${N_CORES}
done


# stack odf and aic filename in a list, in order of increasing ratios
declare -a ODFFILELIST
declare -a AICFILELIST
for RATIO in ${RATIOS[@]};
do
    TMPODFFILE=${ODF_DIR}/sharpen_ratios/csa_sharp_r${RATIO}.nii.gz;
    ODFFILELIST[${#ODFFILELIST[@]}+1]=$TMPODFFILE;
    TMPAICFILE=${ODF_DIR}/aic_ratios/aic_csa_sharp_r${RATIO}.nii.gz;
    AICFILELIST[${#AICFILELIST[@]}+1]=$TMPAICFILE;
done


# # Picks the ratio with lowest AIC for each voxel
# python3 ${SCRIPTS}/combine_aic.py \
#         --iaic ${AICFILELIST[@]} \
#         --iodf ${ODFFILELIST[@]} \
#         --mask ${DIFF_DATA_DIR}/mask.nii.gz \
#         --ratios ${RATIOS[@]} \
#         --oodf ${ODF_DIR}/best_voxelwise_aic_odf.nii.gz \
#         --oaic ${ODF_DIR}/aic_ratios/best_voxelwise_aic_aic.nii.gz \
#         --oratio ${ODF_DIR}/best_voxelwise_aic_ratio.nii.gz



# Picks the ratio with lowest AIC for each voxel in neighborhood
python3 ${SCRIPTS}/combine_aic_neigh.py \
        --iaic ${AICFILELIST[@]} \
        --iodf ${ODFFILELIST[@]} \
        --mask ${DIFF_DATA_DIR}/mask.nii.gz \
        --ratios ${RATIOS[@]} \
        --oodf ${ODF_DIR}/odf_best_neighborhood_aic.nii.gz \
        --oaic ${ODF_DIR}/aic_neighborhood_aic.nii.gz \
        --oratio ${ODF_DIR}/ratio_best_neighborhood_aic.nii.gz


echo 'Extracting peaks from best AIC ODFs'
python3 ${SCRIPTS}/peak_extraction.py \
        ${ODF_DIR}/odf_best_neighborhood_aic.nii.gz \
        ${ODF_DIR}/nufo_best_neighborhood_aic.nii.gz \
        ${ODF_DIR}/dir_best_neighborhood_aic.nii.gz \
        ${ODF_DIR}/len_best_neighborhood_aic.nii.gz \
        --relth 0.25 --minsep 25 --maxn 10 \
        --mask ${DIFF_DATA_DIR}/mask.nii.gz


echo 'Normalize ODF'
python3 ${SCRIPTS}/sh_odf_normalize.py \
        ${ODF_DIR}/odf_best_neighborhood_aic.nii.gz \
        ${ODF_DIR}/odf_best_neighborhood_aic_normalized.nii.gz



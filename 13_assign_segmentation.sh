#!/bin/bash

# Load Local Variables
source ./SET_VARIABLES.sh


# Check Segmentations
mrview ${TISSUE_SEGMENTATION_DIR}/*fuzzy*.nii.gz

# Average input classes for WM Mask
# e.g., 
# INPUT_CLASSES_WM_MASK=\
# ${TISSUE_SEGMENTATION_DIR}/'noFA_fuzzy_label_4class_idx_1.nii.gz '\
# ${TISSUE_SEGMENTATION_DIR}/'noFA_fuzzy_label_3class_idx_0.nii.gz '\
# ${TISSUE_SEGMENTATION_DIR}/'fuzzy_label_4class_idx_1.nii.gz '\
# ${TISSUE_SEGMENTATION_DIR}/'fuzzy_label_3class_idx_2.nii.gz '\

INPUT_CLASSES_WM_MASK=''

mrview $INPUT_CLASSES_WM_MASK

# Average input classes for GM Mask
INPUT_CLASSES_GM_MASK=''

mrview $INPUT_CLASSES_GM_MASK


INPUT_CLASSES_NO_BRAIN=''

mrview $INPUT_CLASSES_NO_BRAIN


#############
# Average Input Classes

python3 ${SCRIPTS}/average_maps.py \
    --data  ${INPUT_CLASSES_WM_MASK} \
    --out   ${TISSUE_SEGMENTATION_DIR}'/WM_Classes_avg.nii.gz'

# mrview ${TISSUE_SEGMENTATION_DIR}'/WM_Classes_avg.nii.gz'

python3 ${SCRIPTS}/average_maps.py \
    --data  ${INPUT_CLASSES_GM_MASK} \
    --out   ${TISSUE_SEGMENTATION_DIR}'/GM_Classes_avg.nii.gz'

# mrview ${TISSUE_SEGMENTATION_DIR}'/GM_Classes_avg.nii.gz'

python3 ${SCRIPTS}/average_maps.py \
    --data  ${INPUT_CLASSES_NO_BRAIN} \
    --out   ${TISSUE_SEGMENTATION_DIR}'/NoBrain_Classes_avg.nii.gz'

# mrview ${TISSUE_SEGMENTATION_DIR}'/NoBrain_Classes_avg.nii.gz'



#############
# Filter Average Masks
#####

## White Matter Mask
${FSL_LOCAL}/fslmaths \
    ${TISSUE_SEGMENTATION_DIR}'/WM_Classes_avg.nii.gz' \
    -kernel 3d \
    -fmedian \
    -thr 0.5 \
    -bin \
    -fillh \
    -kernel 3d \
    -dilf \
    ${TISSUE_SEGMENTATION_DIR}'/WM_Classes_avg_filt_bin.nii.gz'

# Extract the largest connected volume in generated mask
maskfilter \
        -force \
        -largest \
        ${TISSUE_SEGMENTATION_DIR}'/WM_Classes_avg_filt_bin.nii.gz' connect ${TISSUE_SEGMENTATION_DIR}'/WM_Classes_avg_filt_bin_connect.nii.gz'

mrview ${TISSUE_SEGMENTATION_DIR}'/WM_Classes_avg_filt_bin_connect.nii.gz'


## Gray Matter Mask
${FSL_LOCAL}/fslmaths \
    ${TISSUE_SEGMENTATION_DIR}'/GM_Classes_avg.nii.gz' \
    -kernel 3d \
    -fmedian \
    -thr 0.5 \
    -bin \
    -fillh \
    ${TISSUE_SEGMENTATION_DIR}'/GM_Classes_avg_filt_bin.nii.gz'

# Extract the largest connected volume in generated mask
maskfilter \
        -force \
        -largest \
        ${TISSUE_SEGMENTATION_DIR}'/GM_Classes_avg_filt_bin.nii.gz' connect ${TISSUE_SEGMENTATION_DIR}'/GM_Classes_avg_filt_bin_connect.nii.gz'

mrview ${TISSUE_SEGMENTATION_DIR}'/GM_Classes_avg_filt_bin_connect.nii.gz'


## No Brain Mask
${FSL_LOCAL}/fslmaths \
    ${TISSUE_SEGMENTATION_DIR}'/NoBrain_Classes_avg.nii.gz' \
    -kernel 3d \
    -fmedian \
    -thr 0.5 \
    -bin \
    -fillh \
    ${TISSUE_SEGMENTATION_DIR}'/NoBrain_Classes_avg_filt_bin.nii.gz'

# Extract the largest connected volume in generated mask
maskfilter \
        -force \
        -largest \
        ${TISSUE_SEGMENTATION_DIR}'/NoBrain_Classes_avg_filt_bin.nii.gz' connect ${TISSUE_SEGMENTATION_DIR}'/NoBrain_Classes_avg_filt_bin_connect.nii.gz'

mrview ${TISSUE_SEGMENTATION_DIR}'/NoBrain_Classes_avg_filt_bin_connect.nii.gz'



mrcat -force \
	${TISSUE_SEGMENTATION_DIR}'/WM_Classes_avg_filt_bin_connect.nii.gz' \
	${TISSUE_SEGMENTATION_DIR}'/GM_Classes_avg_filt_bin_connect.nii.gz' \
	${TISSUE_SEGMENTATION_DIR}'/NoBrain_Classes_avg_filt_bin_connect.nii.gz' \
	${TISSUE_SEGMENTATION_DIR}'/seg_raw_rgb.nii.gz'


# Check the results
mrview \
    -load ${TISSUE_SEGMENTATION_DIR}'/seg_raw_rgb.nii.gz' \
    -interpolation 0  \
    -mode 2 \
    -overlay.load ${TISSUE_SEGMENTATION_DIR}/flash_contr1_warp.nii.gz \
    -overlay.opacity 0.5 \
    -overlay.interpolation 0 \
    -overlay.colourmap 0 


# Generate more accurate brain mask 
${FSL_LOCAL}/fslmaths \
	${TISSUE_SEGMENTATION_DIR}'/mask.nii.gz' \
	-sub \
	${TISSUE_SEGMENTATION_DIR}'/NoBrain_Classes_avg_filt_bin_connect.nii.gz' \
    -kernel 3d \
    -eroF \
    -dilF \
	${TISSUE_SEGMENTATION_DIR}'/mask_accurate.nii.gz' 

maskfilter \
        -force \
        -largest \
        ${TISSUE_SEGMENTATION_DIR}'/mask_accurate.nii.gz' connect ${TISSUE_SEGMENTATION_DIR}'/mask_accurate_connect.nii.gz'


#!/bin/bash

# Load Local Variables
source ./SET_VARIABLES.sh

# Copy nii files to noisemap directory
echo "Copy nii files to noisemap directory"
cp ${NII_RAW_DIR}/*${NOISE_SCAN}P1.nii.gz ${NOISEMAP_DIR}/noisemap.nii.gz

# Reshape image matrix to resemble MNI space
echo "Reshape image matrix to resemble MNI space"
python3 ${SCRIPTS}/reshape_volume.py \
	--in ${NOISEMAP_DIR}/noisemap.nii.gz \
	--out ${NOISEMAP_DIR}/noisemap_reshape.nii.gz \
	--ord ${RESHAPE_ARRAY_ORD} \
	--inv ${RESHAPE_ARRAY_INV} \
	--res ${RES}

mv -f ${NOISEMAP_DIR}/noisemap_reshape.nii.gz ${NOISEMAP_DIR}/noisemap.nii.gz

mv ${NOISEMAP_DIR}/noisemap.nii.gz ${NOISEMAP_DIR}/noisemap_unscaled.nii.gz 
${FSL_LOCAL}/fslmaths ${NOISEMAP_DIR}/noisemap_unscaled.nii.gz \
	-mul ${DATA_RESCALING} \
	${NOISEMAP_DIR}/noisemap.nii.gz \
	-odt float 



####################################
# Exclude "Patches of Signal" from the noise analysis
python3 ${SCRIPTS}/sigma_along_axes.py \
	--in ${NOISEMAP_DIR}/noisemap.nii.gz \
	--out ${NOISEMAP_DIR}/sigma_variation.txt \
	--axes 0,2


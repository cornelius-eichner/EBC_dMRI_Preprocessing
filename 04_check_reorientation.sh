#!/bin/bash

# Load Local Variables
source ./SET_VARIABLES.sh

# Copy nii files to topup directory
echo "Copy nii files to MNI reorient directory"
cp ${NII_RAW_DIR}/*${CHECK_REORIENT_SCAN}P1.nii.gz ${REORIENT_DIR}/data.nii.gz


# Reshape image matrix to resemble MNI space
echo "Reshape image matrix to resemble MNI space"
python3 ${SCRIPTS}/reshape_volume.py \
	--in ${REORIENT_DIR}/data.nii.gz \
	--out ${REORIENT_DIR}/data_reshape.nii.gz \
	--ord ${RESHAPE_ARRAY_ORD} \
	--inv ${RESHAPE_ARRAY_INV} \
	--res ${RES}

# Print data header information
mrinfo ${REORIENT_DIR}/data.nii.gz 
mrinfo ${REORIENT_DIR}/data_reshape.nii.gz 


####################################
# Rescale Data to prevent very small numbers

mv ${REORIENT_DIR}/data_reshape.nii.gz ${REORIENT_DIR}/data_reshape_unscaled.nii.gz 
${FSL_LOCAL}/fslmaths ${REORIENT_DIR}/data_reshape_unscaled.nii.gz \
	-mul ${DATA_RESCALING} \
	${REORIENT_DIR}/data_reshape.nii.gz \
	-odt float 

#
##################




# Show reoriented data alongside with MNI brain
mrview \
	-load ${REORIENT_DIR}/data_reshape.nii.gz \
	-interpolation 0  \
	-mode 2 &

mrview \
	-load /data/pt_02101_dMRI/software/fsl6/data/standard/MNI152_T1_1mm_brain.nii.gz \
	-interpolation 0 \
	-mode 2 &


#!/bin/bash

# Load Local Variables
source ./SET_VARIABLES.sh
source ${FSLDIR}/etc/fslconf/fsl.sh

# Copy nii files to topup directory
echo "Copy nii files to topup directory"
cp ${NII_RAW_DIR}/*X${TOPUP_LR_RUN}P1.nii.gz ${TOPUP_DIR}/data_LR.nii.gz
cp ${NII_RAW_DIR}/*X${TOPUP_RL_RUN}P1.nii.gz ${TOPUP_DIR}/data_RL.nii.gz

# Reshape image matrix to resemble MNI space
echo "Reshape image matrix to resemble MNI space"
python3 ${SCRIPTS}/reshape_volume.py \
	--in ${TOPUP_DIR}/data_LR.nii.gz \
	--out ${TOPUP_DIR}/data_LR_reshape.nii.gz \
	--ord ${RESHAPE_ARRAY_ORD} \
	--inv ${RESHAPE_ARRAY_INV} \
	--res ${RES}

python3 ${SCRIPTS}/reshape_volume.py \
	--in ${TOPUP_DIR}/data_RL.nii.gz \
	--out ${TOPUP_DIR}/data_RL_flipped.nii.gz \
	--ord ${RESHAPE_ARRAY_ORD} \
	--inv ${RESHAPE_ARRAY_INV} \
	--res ${RES}

python3 ${SCRIPTS}/reshape_volume.py \
	--in ${TOPUP_DIR}/data_RL_flipped.nii.gz \
	--out ${TOPUP_DIR}/data_RL_reshape.nii.gz \
	--ord 0,1,2 \
	--inv 0 \
	--res ${RES}


# Correct for shift along x axis of RL-data
echo "Correct for shift along x axis of RL-data"
python3 ${SCRIPTS}/roll_align_data.py \
	--in ${TOPUP_DIR}/data_RL_reshape.nii.gz \
	--ref ${TOPUP_DIR}/data_LR_reshape.nii.gz \
	--out ${TOPUP_DIR}/data_RL_reshape_shift.nii.gz \
	--axis 0

# Combine the corrected data and remove artifacts from prior steps
echo "Combine the corrected data and remove artifacts from prior steps"
${FSL_LOCAL}/fslmerge -t \
	${TOPUP_DIR}/data.nii.gz \
	${TOPUP_DIR}/data_LR_reshape.nii.gz \
	${TOPUP_DIR}/data_RL_reshape_shift.nii.gz 

rm -rf ${TOPUP_DIR}/data_*.nii.gz

# Run Topup Algorithm
echo "Run Topup Algorithm"
${FSL_LOCAL}/topup \
	--imain=${TOPUP_DIR}/data.nii.gz \
	--datain=${CONFIG_DIR}/topup/acqp \
	--config=${CONFIG_DIR}/topup/b02b0.cnf \
	--out=${TOPUP_DIR}/topup \
	--fout=${TOPUP_DIR}/topup_field.nii.gz \
	--iout=${TOPUP_DIR}/data_unwarp.nii.gz \
	-v 

# Display Topup Corrected Data
echo "Show Corrected Data"
mrview ${TOPUP_DIR}/data_unwarp.nii.gz


echo $0 " Done" 
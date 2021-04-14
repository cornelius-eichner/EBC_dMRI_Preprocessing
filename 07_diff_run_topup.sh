#!/bin/bash

# Load Local Variables
source ./SET_VARIABLES.sh
#source ${FSLDIR}/etc/fslconf/fsl.sh
source ${FSL_LOCAL}/etc/fslconf/fsl.sh



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

if [ $FLAG_TOPUP_CORR == "TRUE" ]
then

	echo "Correct along read axis for different gradient trajectories"
	${FSL_LOCAL}/fnirt \
		--ref=${TOPUP_DIR}/data_LR_reshape.nii.gz \
		--in=${TOPUP_DIR}/data_RL_reshape_shift.nii.gz \
		--warpres=2,2,2 \
		--infwhm=3,2,1,1 \
		--reffwhm=4,2,0,0 \
		--fout=${TOPUP_DIR}/fnirt_field.nii.gz \
		--iout=${TOPUP_DIR}/fnirt_data.nii.gz \
		-v

	# Split Nonlinear Warp Field
	${FSL_LOCAL}/fslsplit ${TOPUP_DIR}/fnirt_field.nii.gz ${TOPUP_DIR}/fnirt_field_split -t

	# Set all dimensions apart y to zero and recombine warp
	${FSL_LOCAL}/fslmaths ${TOPUP_DIR}/fnirt_field_split*0.nii.gz -mul 0 ${TOPUP_DIR}/fnirt_field_split*0.nii.gz
	${FSL_LOCAL}/fslmaths ${TOPUP_DIR}/fnirt_field_split*2.nii.gz -mul 0 ${TOPUP_DIR}/fnirt_field_split*2.nii.gz

	${FSL_LOCAL}/fslmerge -t ${TOPUP_DIR}/fnirt_field_only_y.nii.gz \
		${TOPUP_DIR}/fnirt_field_split*0.nii.gz \
		${TOPUP_DIR}/fnirt_field_split*1.nii.gz \
		${TOPUP_DIR}/fnirt_field_split*2.nii.gz

	# Set Warpfield to relative convention
	echo "Forcing Warp to Relative"
	${FSL_LOCAL}/convertwarp \
		-w ${TOPUP_DIR}/fnirt_field_only_y.nii.gz \
		-r ${TOPUP_DIR}/data_LR_reshape.nii.gz \
		-o ${TOPUP_DIR}/fnirt_field_only_y.nii.gz \
		--relout

	# Calculate Jacobian of new warpfield
	python3 ${SCRIPTS}/calc_jacobian.py \
		--in ${TOPUP_DIR}/fnirt_field_only_y.nii.gz \
		--out ${TOPUP_DIR}/fnirt_field_only_y_jacobian.nii.gz

	# Apply Warp Field
	${FSL_LOCAL}/applywarp \
		-i ${TOPUP_DIR}/data_RL_reshape_shift.nii.gz \
		-r ${TOPUP_DIR}/data_LR_reshape.nii.gz \
		-o ${TOPUP_DIR}/data_RL_reshape_shift_warp.nii.gz \
		-w ${TOPUP_DIR}/fnirt_field_only_y.nii.gz \
		--interp=spline \
		--datatype=float

	# Correct Warped Intensity with Jacobian Determinant
	${FSL_LOCAL}/fslmaths \
		${TOPUP_DIR}/data_RL_reshape_shift_warp.nii.gz \
		-mul ${TOPUP_DIR}/fnirt_field_only_y_jacobian.nii.gz \
		${TOPUP_DIR}/data_RL_reshape_shift_warp_jac.nii.gz


	# Combine the corrected data
	echo "Combine the corrected data"
	${FSL_LOCAL}/fslmerge -t \
		${TOPUP_DIR}/data.nii.gz \
		${TOPUP_DIR}/data_LR_reshape.nii.gz \
		${TOPUP_DIR}/data_RL_reshape_shift_warp_jac.nii.gz

else 
	echo "Combine the corrected data"
	${FSL_LOCAL}/fslmerge -t \
		${TOPUP_DIR}/data.nii.gz \
		${TOPUP_DIR}/data_LR_reshape.nii.gz \
		${TOPUP_DIR}/data_RL_reshape_shift.nii.gz

fi 

echo "Remove Artifacts from Prior Calculations"
rm -rf ${TOPUP_DIR}/data_* ${TOPUP_DIR}/fnirt*

# N4 Bias Correction
N4BiasFieldCorrection \
	-i ${TOPUP_DIR}/data.nii.gz \
	-o [${TOPUP_DIR}/data_N4.nii.gz,${TOPUP_DIR}/N4_biasfield.nii.gz] \
	-d 4 \
	-v

# Run Topup Algorithm
echo "Run Topup Algorithm"
${FSL_LOCAL}/topup \
	--imain=${TOPUP_DIR}/data_N4.nii.gz \
	--datain=${CONFIG_DIR}/topup/acqp \
	--config=${CONFIG_DIR}/topup/b02b0.cnf \
	--out=${TOPUP_DIR}/topup \
	--fout=${TOPUP_DIR}/topup_field.nii.gz \
	--iout=${TOPUP_DIR}/data_unwarp.nii.gz \
	-v 

# Display Topup Corrected Data
echo "Show Corrected Data"
mrview \
	-load ${TOPUP_DIR}/data_N4.nii.gz \
	-interpolation 0 \
	-load ${TOPUP_DIR}/data_unwarp.nii.gz \
	-interpolation 0 \
	-load ${TOPUP_DIR}/topup_field.nii.gz \
	-interpolation 0 \
	-mode 2 &


echo $0 " Done" 
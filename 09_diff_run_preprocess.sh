#!/bin/bash

echo 'Running dMRI processing, make sure to have ANTS running (for N4), next to otherwise active environments'

# Load Local Variables
source ./SET_VARIABLES.sh


####################################
# MP PCA Denoising

echo 'Bias Correction'

# Noise Debiasing with Noisemap acquisition
python3 ${SCRIPTS}/ncchi_bias_correct.py \
	--in ${DIFF_DATA_DIR}/data.nii.gz \
	--sig ${NOISEMAP_DIR}/sigmas.nii.gz \
	--N ${NOISEMAP_DIR}/Ns.nii.gz \
	--axes 0,2 \
	--out ${DIFF_DATA_DIR}/data_debias.nii.gz

${FSL_LOCAL}/fslmaths ${DIFF_DATA_DIR}/data.nii.gz \
	-sub ${DIFF_DATA_DIR}/data_debias.nii.gz \
	${DIFF_DATA_DIR}/data_debias_residual.nii.gz

echo 'MP PCA Denoising'

dwidenoise -f ${DIFF_DATA_DIR}/data_debias.nii.gz \
	${DIFF_DATA_DIR}/data_debias_denoise.nii.gz \
	-mask ${DIFF_DATA_DIR}/mask.nii.gz \
	-noise ${DIFF_DATA_DIR}/data_noise.nii.gz

${FSL_LOCAL}/fslmaths ${DIFF_DATA_DIR}/data_debias.nii.gz \
	-sub ${DIFF_DATA_DIR}/data_debias_denoise.nii.gz \
	-mas ${DIFF_DATA_DIR}/mask.nii.gz \
	${DIFF_DATA_DIR}/data_noise_residual.nii.gz

mrview 	-mode 2 \
	-load ${DIFF_DATA_DIR}/data.nii.gz \
	-interpolation 0 \
	-load ${DIFF_DATA_DIR}/data_debias.nii.gz \
	-interpolation 0 \
	-load ${DIFF_DATA_DIR}/data_debias_denoise.nii.gz \
	-interpolation 0 \
	-load ${DIFF_DATA_DIR}/data_noise.nii.gz \
	-interpolation 0 \
	-load ${DIFF_DATA_DIR}/data_noise_residual.nii.gz \
	-interpolation 0 \
	-load ${DIFF_DATA_DIR}/data_debias_residual.nii.gz \
	-interpolation 0 &

#
##################



####################################
# Detrending the tissue heating effect of increased diffusivity
echo 'Signal Detrending'

source ./SET_VARIABLES.sh

if [[ ${HEAT_CORRECTION} == "YES" ]]
then
	echo 'Performing Heat Correction'
	python3 ${SCRIPTS}/signal_temp_equalizer.py \
	--last 40 \
	--mask ${DIFF_DATA_DIR}/mask.nii.gz \
	${DIFF_DATA_DIR}/data_debias_denoise.nii.gz \
	${DIFF_DATA_DIR}/data.bval \
	${DIFF_DATA_DIR}/data.bvec \
	${DIFF_DATA_DIR}/data_debias_denoise_detrend.nii.gz \
	${DIFF_DATA_DIR}/computed_ks.nii.gz

	# The second volume of computed_ks.nii.gz can be a good estimator for a WM mask, extract this volume and run again
	${FSL_LOCAL}/fslroi \
		${DIFF_DATA_DIR}/computed_ks.nii.gz \
		${DIFF_DATA_DIR}/computed_ks_vol1.nii.gz \
		1 1

	# Threshold the ks to identify the white matter
	${FSL_LOCAL}/fslmaths \
		${DIFF_DATA_DIR}/computed_ks_vol1.nii.gz \
		-uthr 0.8 \
		-bin \
		-kernel 3d -fillh26 \
		-kernel 3d -fillh26 \
		-kernel 3d -eroF \
		-mas ${DIFF_DATA_DIR}/mask.nii.gz \
		${DIFF_DATA_DIR}/wm_mask.nii.gz

	mrview 	-mode 2 \
	-load ${DIFF_DATA_DIR}/computed_ks_vol1.nii.gz \
	-interpolation 0 \
	-overlay.load ${DIFF_DATA_DIR}/wm_mask.nii.gz \
	-overlay.interpolation 0 &


	# Extract the largest connected volume in generated mask
	maskfilter -f -largest ${DIFF_DATA_DIR}/wm_mask.nii.gz connect ${DIFF_DATA_DIR}/wm_mask_connect.nii.gz

	# Dilate the mask 
	maskfilter -f -npass 2 ${DIFF_DATA_DIR}/wm_mask_connect.nii.gz dilate ${DIFF_DATA_DIR}/wm_mask_connect_dil.nii.gz

	mv -f ${DIFF_DATA_DIR}/wm_mask_connect_dil.nii.gz ${DIFF_DATA_DIR}/wm_mask.nii.gz
	rm -f ${DIFF_DATA_DIR}/wm_mask_*

	python3 ${SCRIPTS}/signal_temp_equalizer.py \
		--last 40 \
		--mask ${DIFF_DATA_DIR}/wm_mask.nii.gz \
		${DIFF_DATA_DIR}/data_debias_denoise.nii.gz \
		${DIFF_DATA_DIR}/data.bval \
		${DIFF_DATA_DIR}/data.bvec \
		${DIFF_DATA_DIR}/data_debias_denoise_detrend.nii.gz \
		${DIFF_DATA_DIR}/computed_ks.nii.gz

elif [[ ${HEAT_CORRECTION} == "NO" ]]
then 
	echo 'Skiping Heat Correction'
	cp -f ${DIFF_DATA_DIR}/data_debias_denoise.nii.gz ${DIFF_DATA_DIR}/data_debias_denoise_detrend.nii.gz
fi

#
##################



####################################
# Eddy correction - Eddy will be performed on B4 bias corrected data. The resulting eddy fields will be applied  to the data
# Incorporate linear registration to FLASH Data

echo 'Eddy Correction'

# Generate files required for eddy 
python3 ${SCRIPTS}/make_fake_eddy_files.py \
	--folder ${DIFF_DATA_DIR}/ \
	--Ndir ${N_DIRECTION} \
	--TE ${TE} \
	--PE ${PE_DIRECTION}

# For some reason, ANTS N4 expects a 4D mask for N4, creating 4D mask using fslmaths
${FSL_LOCAL}/fslmaths \
	${DIFF_DATA_DIR}/data_debias_denoise_detrend.nii.gz \
	-mas ${DIFF_DATA_DIR}/mask.nii.gz \
	-bin \
	${DIFF_DATA_DIR}/mask_4D.nii.gz \
	-odt int

# Estimate N4 Bias Correction of Median B0 Data
N4BiasFieldCorrection \
	-i ${DIFF_DATA_DIR}/data_debias_denoise_detrend.nii.gz \
	-x ${DIFF_DATA_DIR}/mask_4D.nii.gz \
	-o [${DIFF_DATA_DIR}/data_N4.nii.gz,${DIFF_DATA_DIR}/N4_biasfield.nii.gz] \
	-d 4 \
	-v

rm -rf ${DIFF_DATA_DIR}/mask_4D.nii.gz 

# Apply bias field correction to entire dMRI dataset
${FSL_LOCAL}/fslmaths \
	${DIFF_DATA_DIR}/data_debias_denoise_detrend.nii.gz \
	-div ${DIFF_DATA_DIR}/data_b0s_mc_N4_biasfield.nii.gz \
	${DIFF_DATA_N4_DIR}/data_N4.nii.gz \
	-odt float

# Run Eddy on N4 Corrected data
${EDDY_PATH} \
	--imain=${DIFF_DATA_N4_DIR}/data_N4.nii.gz \
	--mask=${DIFF_DATA_DIR}/mask.nii.gz \
	--index=${DIFF_DATA_DIR}/index \
	--acqp=${DIFF_DATA_DIR}/acqp \
	--bvecs=${DIFF_DATA_DIR}/data.bvec \
	--bvals=${DIFF_DATA_DIR}/data.bval_round \
	--topup=${TOPUP_DIR}/topup \
	--out=${EDDY_DIR}/eddy \
	--dfields=${EDDY_FIELDS_DIR}/eddy \
	--repol \
	--interp=spline \
	--data_is_shelled \
	-v

# Move Eddy Fields to respective folder
mv -f ${EDDY_DIR}/*displacement_fields* ${EDDY_FIELDS_DIR}/

# Check Eddy Correction
mrview -mode 2 \
	-load ${EDDY_DIR}/eddy.nii.gz \
	-interpolation 0 &

# Split original data
echo "Splitting dataset to specified out_folder" 
${FSL_LOCAL}/fslsplit \
	${DIFF_DATA_DIR}/data_debias_denoise_detrend.nii.gz \
	${DIFF_DATA_DIR}/split/

# Force Warp Fields Relative and Calculate Jacobian Determinant
echo "Converting Warp Fields to Relative Convention" 
for filename in ${EDDY_FIELDS_DIR}/* ; do
	echo "Converting Warp Field" ${filename##*/}
	${FSL_LOCAL}/convertwarp \
		-w ${EDDY_FIELDS_DIR}/${filename##*/} \
		-r ${DIFF_DATA_DIR}/data_b0s_mc_mean_median.nii.gz \
		-o ${EDDY_FIELDS_REL_DIR}/${filename##*/} \
		--relout 
done

echo "Calculate Jacobi Determinant" 
for filename in ${EDDY_FIELDS_REL_DIR}/* ; do
	echo "Calculating Jacobi Determinant of Warp Field" ${filename##*/}
	python3 ${SCRIPTS}/calc_jacobian.py \
		--in ${EDDY_FIELDS_REL_DIR}/${filename##*/} \
		--out ${EDDY_FIELDS_JAC_DIR}/${filename##*/}
done

# Warp the data and apply jacobi determinant
echo "Apply Warp Fields to Split Volumes" 
python3 ${SCRIPTS}/warp_data.py \
    --split_folder ${SPLIT_DIR} \
    --warp_folder ${EDDY_FIELDS_REL_DIR} \
    --jac_folder ${EDDY_FIELDS_JAC_DIR} \
    --out_folder ${SPLIT_WARPED_DIR}


echo "Stitching together Measurements" 
${FSL_LOCAL}/fslmerge -t ${DIFF_DATA_DIR}/data_debias_denoise_detrend_eddy.nii.gz ${SPLIT_WARPED_DIR}/*nii.gz

#
##################


####################################
# DTI Fit for Quality Control

echo 'DTI Fit for Quality Control'

${FSL_LOCAL}/dtifit -k ${DIFF_DATA_DIR}/data_debias_denoise_detrend_eddy.nii.gz \
					-m ${DIFF_DATA_DIR}/mask.nii.gz \
					-r ${DIFF_DATA_DIR}/data.bvec \
					-b ${DIFF_DATA_DIR}/data.bval \
					-o ${DTI_DIR}/dti \
					-w -V

# Create a scaled FA image for improved visualization contrast
${FSL_LOCAL}/fslmaths ${DTI_DIR}/dti_FA.nii.gz -mul 2 ${DTI_DIR}/dti_FA_mul2.nii.gz 

fsleyes ${DTI_DIR}/dti_FA* ${DTI_DIR}/dti_FA_mul2.nii.gz ${DTI_DIR}/dti_MD* ${DTI_DIR}/dti_V1* 

#
##################


####################################
# Copy corrected data to release folder
cp ${DIFF_DATA_DIR}/data_debias_denoise_detrend_eddy.nii.gz ${DIFF_DATA_RELEASE_DIR}/data.nii.gz
cp ${DIFF_DATA_DIR}/mask.nii.gz ${DIFF_DATA_RELEASE_DIR}/mask.nii.gz
cp ${DIFF_DATA_DIR}/data.bval ${DIFF_DATA_RELEASE_DIR}/data.bval
cp ${EDDY_DIR}/*bvecs ${DIFF_DATA_RELEASE_DIR}/data.bvec




####################################
# Normalize Data with b0

echo 'Normalize Data with b0'

python3 ${SCRIPTS}/normalize_data.py \
	--in ${DIFF_DATA_DIR}/data_debias_denoise_detrend_eddy.nii.gz \
	--mask ${DIFF_DATA_DIR}/mask.nii.gz \
	--bval ${DIFF_DATA_DIR}/data.bval \
	--bvec ${EDDY_DIR}/*bvecs \
	--out_folder ${DIFF_DATA_NORM_RELEASE_DIR}

#
##################


echo $0 " Done" 
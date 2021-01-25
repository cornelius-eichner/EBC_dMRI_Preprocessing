#!/bin/bash

# Load Local Variables
source ./SET_VARIABLES.sh


####################################
# Put together the data from various files

# Assemble all DIFF_SCANS from raw nifti folder
echo "Loading Data"
${FSL_LOCAL}/fslmerge -t ${DIFF_DATA_DIR}/data.nii.gz \
	./nifti_raw/*${DIFF_SCANS[0]}P1.nii.gz \
	./nifti_raw/*${DIFF_SCANS[1]}P1.nii.gz \
	./nifti_raw/*${DIFF_SCANS[2]}P1.nii.gz \
	./nifti_raw/*${DIFF_SCANS[3]}P1.nii.gz \
	./nifti_raw/*${DIFF_SCANS[4]}P1.nii.gz \
	./nifti_raw/*${DIFF_SCANS[5]}P1.nii.gz \
	./nifti_raw/*${DIFF_SCANS[6]}P1.nii.gz \
	./nifti_raw/*${DIFF_SCANS[7]}P1.nii.gz \
	./nifti_raw/*${DIFF_SCANS[8]}P1.nii.gz 

# Load bvecs and bvals from Bruker method file
echo "Loading bvecs bvals"
rm -f ${DIFF_DATA_DIR}/data.bv* 
>${DIFF_DATA_DIR}/data.bvec 
>${DIFF_DATA_DIR}/data.bval 

# Loop over raw data folder and concatenate bvecs bvals files 
for i_scan in ${DIFF_SCANS[*]}
do
    python3 ${SCRIPTS}/bvec_bval_from_method.py ${BRUKER_RAW_DIR}/${i_scan}/method ${DIFF_DATA_DIR}/${i_scan}.bvec ${DIFF_DATA_DIR}/${i_scan}.bval
    paste -d ' ' ${DIFF_DATA_DIR}/${i_scan}.bvec >> ${DIFF_DATA_DIR}/data.bvec
    paste -d ' ' ${DIFF_DATA_DIR}/${i_scan}.bval >> ${DIFF_DATA_DIR}/data.bval

    rm -f ${DIFF_DATA_DIR}/${i_scan}.bvec ${DIFF_DATA_DIR}/${i_scan}.bval
done

#
##################



####################################
# Reshape Data to match MNI orientation

python3 ${SCRIPTS}/reshape_volume.py \
	--in ${DIFF_DATA_DIR}/data.nii.gz \
	--out ${DIFF_DATA_DIR}/data_reshape.nii.gz \
	--ord ${RESHAPE_ARRAY_ORD} \
	--inv ${RESHAPE_ARRAY_INV} \
	--res ${RES}

python3 ${SCRIPTS}/reorder_bvec.py \
	--in ${DIFF_DATA_DIR}/data.bvec \
	--ord ${RESHAPE_BVECS_ORD} \
	--out ${DIFF_DATA_DIR}/bvec_reshape

# Overwrite non-oriented volumes
mv -f ${DIFF_DATA_DIR}/data_reshape.nii.gz ${DIFF_DATA_DIR}/data.nii.gz
mv -f ${DIFF_DATA_DIR}/bvec_reshape ${DIFF_DATA_DIR}/data.bvec

#
##################


####################################
# Rescale Data to prevent very small numbers

mv -f ${DIFF_DATA_DIR}/data.nii.gz ${DIFF_DATA_DIR}/data_unscaled.nii.gz 
${FSL_LOCAL}/fslmaths ${DIFF_DATA_DIR}/data_unscaled.nii.gz \
	-mul ${DATA_RESCALING} \
	${DIFF_DATA_DIR}/data.nii.gz \
	-odt float 

#
##################



####################################
# Generate mask from b0 values

# round the bvals file to use dwiextract -b0
python3 ${SCRIPTS}/round_bvals.py --in ${DIFF_DATA_DIR}/data.bval --out ${DIFF_DATA_DIR}/data.bval_round

# Extract b0 volumes
dwiextract \
	-bzero \
	-fslgrad ${DIFF_DATA_DIR}/data.bvec ${DIFF_DATA_DIR}/data.bval_round \
	${DIFF_DATA_DIR}/data.nii.gz \
	${DIFF_DATA_DIR}/data_b0s.nii.gz

mrview ${DIFF_DATA_DIR}/data_b0s.nii.gz \
	-colourmap 1 \
	-interpolation 0 &

# MC correct the b0 volumes
${FSL_LOCAL}/mcflirt \
	-in ${DIFF_DATA_DIR}/data_b0s.nii.gz \
	-out ${DIFF_DATA_DIR}/data_b0s_mc.nii.gz \
	-refvol 0

mrview ${DIFF_DATA_DIR}/data_b0s_mc.nii.gz \
	-colourmap 1 \
	-interpolation 0 &

# Filter Volumes for mask thresholding
${FSL_LOCAL}/fslmaths \
	${DIFF_DATA_DIR}/data_b0s_mc.nii.gz \
	-Tmean \
	-kernel 3d \
	-fmedian ${DIFF_DATA_DIR}/data_b0s_mc_mean_median.nii.gz

mrview ${DIFF_DATA_DIR}/data_b0s_mc_mean_median.nii.gz \
	-colourmap 1 \
	-interpolation 0 & 

# Find THRESHOLD VALUE in a histogram
python3 ${SOFTWARE}/quickviz/quickviz.py --his ${DIFF_DATA_DIR}/data_b0s_mc_mean_median.nii.gz --loghis

# Update mask threshold variable
source ./SET_VARIABLES.sh

# Generate mask by thresholing the b0 volumes (FLS maths)
${FSL_LOCAL}/fslmaths \
	${DIFF_DATA_DIR}/data_b0s_mc.nii.gz \
	-Tmean \
	-kernel 3d \
	-fmedian \
	-thr ${MASK_THRESHOLD} \
	-bin \
	-fillh26 ${DIFF_DATA_DIR}/mask.nii.gz \
	-odt int

# Extract the largest connected volume in generated mask
maskfilter \
	-f \
	-largest \
	${DIFF_DATA_DIR}/mask.nii.gz connect ${DIFF_DATA_DIR}/mask_fit_connect.nii.gz

# Dilate the mask 
maskfilter \
	-f \
	-npass 2 \
	${DIFF_DATA_DIR}/mask_fit_connect.nii.gz dilate ${DIFF_DATA_DIR}/mask_fit_connect_dil.nii.gz

# Check the results
mrview \
	-load ${DIFF_DATA_DIR}/data_b0s_mc_mean_median.nii.gz \
	-interpolation 0  \
	-mode 2 \
	-overlay.load ${DIFF_DATA_DIR}/mask_fit_connect_dil.nii.gz \
	-overlay.opacity 0.5 \
	-overlay.interpolation 0 \
	-overlay.colourmap 3 

# Get rid of the evidence 
rm -f ${DIFF_DATA_DIR}/mask.nii.gz ${DIFF_DATA_DIR}/mask_fit_connect.nii.gz 
mv -f ${DIFF_DATA_DIR}/mask_fit_connect_dil.nii.gz ${DIFF_DATA_DIR}/mask.nii.gz

#
##################


####################################
# Check the bvec orientation

mkdir -p ${DIFF_DATA_DIR}/test_dti
${FSL_LOCAL}/dtifit \
	-k ${DIFF_DATA_DIR}/data.nii.gz \
	-m ${DIFF_DATA_DIR}/mask.nii.gz \
	-r ${DIFF_DATA_DIR}/data.bvec \
	-b ${DIFF_DATA_DIR}/data.bval \
	-o ${DIFF_DATA_DIR}/test_dti/dti

fsleyes ${DIFF_DATA_DIR}/test_dti/dti_FA* ${DIFF_DATA_DIR}/test_dti/dti_V1* ${DIFF_DATA_DIR}/test_dti/dti_MD*
rm -rf ${DIFF_DATA_DIR}/test_dti

#
##################



####################################
# MP PCA Denoising

# Noise Debiasing with Noisemap acquisition
python3 ${SCRIPTS}/rician_bias_correct.py \
	--in ${DIFF_DATA_DIR}/data.nii.gz \
	--sig ${NOISEMAP_DIR}/sigma_variation.txt \
	--axes 0,2 \
	--out ${DIFF_DATA_DIR}/data_debias.nii.gz

${FSL_LOCAL}/fslmaths ${DIFF_DATA_DIR}/data.nii.gz \
	-sub ${DIFF_DATA_DIR}/data_debias.nii.gz \
	${DIFF_DATA_DIR}/data_debias_residual.nii.gz

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

# Generate files required for eddy 
python3 ${SCRIPTS}/make_fake_eddy_files.py \
	--folder ${DIFF_DATA_DIR}/ \
	--Ndir ${N_DIRECTION} \
	--TE ${TE} \
	--PE ${PE_DIRECTION}

# N4 Bias Correction of Diffusion Data
N4BiasFieldCorrection \
	-i ${DIFF_DATA_DIR}/data_debias_denoise_detrend.nii.gz \
	-o ${DIFF_DATA_N4_DIR}/data_N4.nii.gz \
	-d 4 \
	-v 

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
	-interpolation 0 

# Split original data
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
python3 ${SCRIPTS}/normalize_data.py \
	--in ${DIFF_DATA_DIR}/data_debias_denoise_detrend_eddy.nii.gz \
	--mask ${DIFF_DATA_DIR}/mask.nii.gz \
	--bval ${DIFF_DATA_DIR}/data.bval \
	--bvec ${EDDY_DIR}/*bvecs \
	--out_folder ${DIFF_DATA_NORM_RELEASE_DIR}

cp 

#
##################

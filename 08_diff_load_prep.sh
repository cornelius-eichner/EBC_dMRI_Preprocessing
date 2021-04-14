#!/bin/bash

# Load Local Variables
source ./SET_VARIABLES.sh


####################################
# Put together the data from various files

# Assemble all DIFF_SCANS from raw nifti folder
echo "Loading Data"
${FSL_LOCAL}/fslmerge -t ${DIFF_DATA_DIR}/data.nii.gz \
	${NII_RAW_DIR}/*X${DIFF_SCANS[0]}P1.nii.gz \
	${NII_RAW_DIR}/*X${DIFF_SCANS[1]}P1.nii.gz \
	${NII_RAW_DIR}/*X${DIFF_SCANS[2]}P1.nii.gz \
	${NII_RAW_DIR}/*X${DIFF_SCANS[3]}P1.nii.gz \
	${NII_RAW_DIR}/*X${DIFF_SCANS[4]}P1.nii.gz \
	${NII_RAW_DIR}/*X${DIFF_SCANS[5]}P1.nii.gz \
	${NII_RAW_DIR}/*X${DIFF_SCANS[6]}P1.nii.gz \
	${NII_RAW_DIR}/*X${DIFF_SCANS[7]}P1.nii.gz \
	${NII_RAW_DIR}/*X${DIFF_SCANS[8]}P1.nii.gz 

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

echo 'Reshape Data to match MNI orientation'

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

echo 'Rescale Data to prevent very small numbers'

mv -f ${DIFF_DATA_DIR}/data.nii.gz ${DIFF_DATA_DIR}/data_unscaled.nii.gz 
${FSL_LOCAL}/fslmaths ${DIFF_DATA_DIR}/data_unscaled.nii.gz \
	-div ${DATA_RESCALING} \
	${DIFF_DATA_DIR}/data.nii.gz \
	-odt float 

#
##################



####################################
# Generate mask from b0 values

echo 'Generate mask from b0 values'

# round the bvals file to use dwiextract -b0
python3 ${SCRIPTS}/round_bvals.py \
	--in ${DIFF_DATA_DIR}/data.bval \
	--out ${DIFF_DATA_DIR}/data.bval_round

# Extract b0 volumes
dwiextract \
	-force \
	-bzero \
	-fslgrad ${DIFF_DATA_DIR}/data.bvec ${DIFF_DATA_DIR}/data.bval_round \
	${DIFF_DATA_DIR}/data.nii.gz \
	${DIFF_DATA_DIR}/data_b0s.nii.gz

# MC correct the b0 volumes
${FSL_LOCAL}/mcflirt \
	-in ${DIFF_DATA_DIR}/data_b0s.nii.gz \
	-out ${DIFF_DATA_DIR}/data_b0s_mc.nii.gz \
	-refvol 0

# Filter Volumes for mask thresholding
${FSL_LOCAL}/fslmaths \
	${DIFF_DATA_DIR}/data_b0s_mc.nii.gz \
	-Tmean \
	-kernel 3d \
	-fmedian ${DIFF_DATA_DIR}/data_b0s_mc_mean_median.nii.gz

mrview \
	-load ${DIFF_DATA_DIR}/data_b0s_mc.nii.gz \
	-interpolation 0 \
	-load ${DIFF_DATA_DIR}/data_b0s.nii.gz \
	-interpolation 0 \
	-load ${DIFF_DATA_DIR}/data_b0s_mc_mean_median.nii.gz \
	-interpolation 0 & 

MASKING_ANSWER="N"
MASKING_DONE="N"
while [ "$MASKING_DONE" == "N" ]; do

	# Generate mask by thresholing the b0 volumes (FLS maths)
	${FSL_LOCAL}/fslmaths \
		${DIFF_DATA_DIR}/data_b0s_mc_mean_median.nii.gz \
		-Tmean \
		-kernel 3d \
		-fmedian \
		-thr ${MASK_THRESHOLD} \
		-bin \
		-fillh26 ${DIFF_DATA_DIR}/mask.nii.gz \
		-odt int

	# Extract the largest connected volume in generated mask
	maskfilter \
		-force \
		-largest \
		${DIFF_DATA_DIR}/mask.nii.gz connect ${DIFF_DATA_DIR}/mask_fit_connect.nii.gz

	# Dilate the mask 
	maskfilter \
		-force \
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

	echo "Did the script choose the correct threshold for the mask ? [Y/N]"
	read MASKING_ANSWER

	if [ $MASKING_ANSWER == "N" ]
	then
	# Find THRESHOLD VALUE in a histogram
	echo 'Adapt MASK_THRESHOLD Variable in SET_VARIABLES.sh to exclude noise peak in histogram'
	python3 ${SCRIPTS}/quickviz.py \
		--his ${DIFF_DATA_DIR}/data_b0s_mc_mean_median.nii.gz \
		--loghis 

	THRS_OLD=$MASK_THRESHOLD # Saving old threshold in variable for replacement in SET_VARIABLES.txt

	echo "Previous mask threshold value:"
	echo $MASK_THRESHOLD

	echo 'Please provide new mask threshold value:'
	read MASK_THRESHOLD
	echo "Repeating procedure with new threshold" ${MASK_THRESHOLD}

	# Saving mask string in set variables file
	THRS_STR_OLD="MASK_THRESHOLD=$THRS_OLD"
	THRS_STR_NEW="MASK_THRESHOLD=$MASK_THRESHOLD"

	sed -i "s/$THRS_STR_OLD/$THRS_STR_NEW/gi" ./SET_VARIABLES.sh

	
	elif [ $MASKING_ANSWER == "Y" ]
	then
	MASKING_DONE="Y"

	else 
	echo "Invalid answer, please repeat"


	fi 

done 


# Get rid of the evidence 
rm -f ${DIFF_DATA_DIR}/mask.nii.gz ${DIFF_DATA_DIR}/mask_fit_connect.nii.gz 
mv -f ${DIFF_DATA_DIR}/mask_fit_connect_dil.nii.gz ${DIFF_DATA_DIR}/mask.nii.gz

#
##################


####################################
# Plot the dMRI timeseries
echo "Plot the dMRI timeseries"

python3 ${SCRIPTS}/plot_timeseries.py \
	--in ${DIFF_DATA_DIR}/data.nii.gz \
	--mask ${DIFF_DATA_DIR}/mask.nii.gz \
	--bvals ${DIFF_DATA_DIR}/data.bval \
	--out ${DIFF_DATA_DIR}

#
##################



####################################
# Check the bvec orientation

echo "Check the bvec orientation"

mkdir -p ${DIFF_DATA_DIR}/test_dti
${FSL_LOCAL}/dtifit \
	-k ${DIFF_DATA_DIR}/data.nii.gz \
	-m ${DIFF_DATA_DIR}/mask.nii.gz \
	-r ${DIFF_DATA_DIR}/data.bvec \
	-b ${DIFF_DATA_DIR}/data.bval \
	-o ${DIFF_DATA_DIR}/test_dti/dti

fsleyes ${DIFF_DATA_DIR}/test_dti/dti_MD* ${DIFF_DATA_DIR}/test_dti/dti_FA* ${DIFF_DATA_DIR}/test_dti/dti_V1* 
rm -rf ${DIFF_DATA_DIR}/test_dti

#
##################


echo $0 " Done" 
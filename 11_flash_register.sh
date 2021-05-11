#!/bin/bash

# Load Local Variables
source ./SET_VARIABLES_local.sh

cp ${FLASH_DIR_FA05}/data.nii.gz ${FLASH_DIR_WARP}/data_flash.nii.gz


echo 'Runing N4 on FLASH Data'
for i in {1..5} 
do 

        current_iter_flash=${FLASH_DIR_WARP}/data_flash_N4_${i}x.nii.gz
        current_iter_flash_field=${FLASH_DIR_WARP}/field_flash_N4_${i}x.nii.gz

        if [ $i == 1 ]
        then 
                previous_iter_flash=${FLASH_DIR_WARP}/data_flash.nii.gz
        else
                previous_iter_flash=${FLASH_DIR_WARP}/data_flash_N4_$( expr $i - 1 )x.nii.gz
        fi

        echo 'N4 FLASH: Run '${i}

        N4BiasFieldCorrection -d 3 \
                -i $previous_iter_flash \
                -o [$current_iter_flash,$current_iter_flash_field]


done

# Get initial mask threshold from average image intensity
MASK_THRESHOLD_FLASH=$(${FSL_LOCAL}/fslstats $current_iter_flash -m)

echo "Creating mask for Ernst Angle FLASH data "
MASKING_DONE="N"
while [ "$MASKING_DONE" == "N" ]; do

        # Generate mask by thresholing the b0 volumes (FLS maths)
        ${FSL_LOCAL}/fslmaths \
                $current_iter_flash \
                -kernel 3d \
                -fmedian \
                -thr ${MASK_THRESHOLD_FLASH} \
                -bin \
                -fillh26 ${FLASH_DIR_WARP}/mask_flash.nii.gz \
                -odt int

        # Extract the largest connected volume in generated mask
        maskfilter \
                -force \
                -largest \
                ${FLASH_DIR_WARP}/mask_flash.nii.gz connect ${FLASH_DIR_WARP}/mask_flash_connect.nii.gz

        # Dilate the mask 
        maskfilter \
                -force \
                -npass 2 \
                ${FLASH_DIR_WARP}/mask_flash_connect.nii.gz dilate ${FLASH_DIR_WARP}/mask_flash_connect_dil.nii.gz

        # Check the results
        mrview \
                -load $current_iter_flash \
                -interpolation 0  \
                -mode 2 \
                -overlay.load ${FLASH_DIR_WARP}/mask_flash_connect_dil.nii.gz \
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
                --his $current_iter_flash \
                --loghis 

        THRS_OLD=$MASK_THRESHOLD_FLASH # Saving old threshold in variable for replacement in SET_VARIABLES.txt

        echo "Previous mask threshold value:"
        echo $MASK_THRESHOLD_FLASH

        echo 'Please provide new mask threshold value:'
        read MASK_THRESHOLD_FLASH
        echo "Repeating procedure with new threshold" ${MASK_THRESHOLD_FLASH}

        # Saving mask string in set variables file
        THRS_STR_OLD="MASK_THRESHOLD_FLASH=$THRS_OLD"
        THRS_STR_NEW="MASK_THRESHOLD_FLASH=$MASK_THRESHOLD_FLASH"
     
        elif [ $MASKING_ANSWER == "Y" ]
        then
        MASKING_DONE="Y"

        else 
        echo "Invalid answer, please repeat"


        fi 

done 

mv -f ${FLASH_DIR_WARP}/mask_flash_connect_dil.nii.gz ${FLASH_DIR_WARP}/mask_flash.nii.gz
rm -f ${FLASH_DIR_WARP}/mask_flash_*.nii.gz


# Copy the EPI Data to the FLASH unwarp folder
cp ${DIFF_DATA_DIR}/mask.nii.gz ${FLASH_DIR_WARP}/mask_epi.nii.gz
echo 'Averaging Topup Warp Data for EPI Reference'
${FSL_LOCAL}/fslmaths \
        ${TOPUP_DIR}/data_unwarp.nii.gz \
        -Tmean \
        ${FLASH_DIR_WARP}/data_epi.nii.gz

# Multiple rounds of N4
echo 'Runing N4 on EPI Data'
for i in {1..5} 
do 

        current_iter_epi=${FLASH_DIR_WARP}/data_epi_N4_${i}x.nii.gz
        current_iter_epi_field=${FLASH_DIR_WARP}/field_epi_N4_${i}x.nii.gz

        if [ $i == 1 ]
        then 
                previous_iter_epi=${FLASH_DIR_WARP}/data_epi.nii.gz
        else
                previous_iter_epi=${FLASH_DIR_WARP}/data_epi_N4_$( expr $i - 1 )x.nii.gz
        fi

        echo 'N4 EPI: Run '${i}

        N4BiasFieldCorrection -d 3 \
                -i $previous_iter_epi \
                -x $mask_move \
                -o [$current_iter_epi,$current_iter_epi_field]


done

data_move_N4=$current_iter_flash
mask_move=${FLASH_DIR_WARP}/mask_flash.nii.gz

data_fix_N4=$current_iter_epi
mask_fix=${FLASH_DIR_WARP}/mask_epi.nii.gz

echo 'Running SyN between FLASH and EPI'
antsRegistration --dimensionality 3 --float 1 \
        --output [${FLASH_DIR_WARP}/flash_to_epi_,${FLASH_DIR_WARP}/data_flash_warped.nii.gz] \
        --interpolation Linear \
        --winsorize-image-intensities [0.005,0.995] \
        --use-histogram-matching 0 \
        --transform Rigid[0.1] \
        --metric MI[$data_fix_N4,$data_move_N4,1,32,Regular,0.25] \
        --convergence [1000x500x250x100,1e-6,10] \
        --shrink-factors 8x4x2x1 \
        --smoothing-sigmas 3x2x1x0 \
        --transform Affine[0.1] \
        --metric MI[$data_fix_N4,$data_move_N4,1,32,Regular,0.25] \
        --convergence [1000x500x250x100,1e-6,10] \
        --shrink-factors 8x4x2x1 \
        --smoothing-sigmas 3x2x1x0 \
        --transform SyN[0.1,3,0] \
        --metric CC[$data_fix_N4,$data_move_N4,1,4] \
        --convergence [400x200x100x50x40,1e-6,10] \
        --shrink-factors 16x8x4x2x1 \
        --smoothing-sigmas 4x3x2x1x0 \
        -x [$mask_fix,$mask_move] \
        -v 1

echo 'Done'


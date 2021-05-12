#!/bin/bash

# Load Local Variables
source ./SET_VARIABLES.sh

echo 'Copy Files to Segmentation Directory'

# Copy FLASH Data to segmentation directory
cp ${FLASH_DIR_FA05}/data.nii.gz 	${TISSUE_SEGMENTATION_DIR}/flash_contr1.nii.gz
cp ${FLASH_DIR_FA12p5}/data.nii.gz 	${TISSUE_SEGMENTATION_DIR}/flash_contr2.nii.gz
cp ${FLASH_DIR_FA25}/data.nii.gz 	${TISSUE_SEGMENTATION_DIR}/flash_contr3.nii.gz
cp ${FLASH_DIR_FA50}/data.nii.gz 	${TISSUE_SEGMENTATION_DIR}/flash_contr4.nii.gz
cp ${FLASH_DIR_FA80}/data.nii.gz 	${TISSUE_SEGMENTATION_DIR}/flash_contr5.nii.gz


# Copy DTI Data to segmentation directory
cp ${DTI_DIR}/dti_FA.nii.gz ${TISSUE_SEGMENTATION_DIR}/dti_FA.nii.gz
cp ${DTI_DIR}/dti_MD.nii.gz ${TISSUE_SEGMENTATION_DIR}/dti_MD.nii.gz

# Extract and average dMRI b0 data to segmentation directory
dwiextract \
	-force \
	-bzero \
	-fslgrad ${DIFF_DATA_DIR}/data.bvec ${DIFF_DATA_DIR}/data.bval_round \
	${DIFF_DATA_RELEASE_DIR}/data.nii.gz  \
	${TISSUE_SEGMENTATION_DIR}/data_b0.nii.gz
${FSL_LOCAL}/fslmaths ${TISSUE_SEGMENTATION_DIR}/data_b0.nii.gz -Tmean ${TISSUE_SEGMENTATION_DIR}/data_b0_avg.nii.gz -odt float
mv -f ${TISSUE_SEGMENTATION_DIR}/data_b0_avg.nii.gz ${TISSUE_SEGMENTATION_DIR}/data_b0.nii.gz


# Copy mask to segmentation directory
cp ${DIFF_DATA_RELEASE_DIR}/mask.nii.gz ${TISSUE_SEGMENTATION_DIR}/mask.nii.gz

echo "Runing 5 x N4 on dMRI b0 Data"
for i in {1..5} 
do 
        current_iter_b0=${TISSUE_SEGMENTATION_DIR}/data_b0_N4_${i}x.nii.gz

        if [ $i == 1 ]
        then 
                previous_iter_b0=${TISSUE_SEGMENTATION_DIR}/data_b0.nii.gz
        else
                previous_iter_b0=${TISSUE_SEGMENTATION_DIR}/data_b0_N4_$( expr $i - 1 )x.nii.gz
        fi

        echo 'N4 b0 dMRI: Run '${i}

        N4BiasFieldCorrection -d 3 \
                -i $previous_iter_b0 \
                -x ${TISSUE_SEGMENTATION_DIR}/mask.nii.gz \
                -o $current_iter_b0
done


echo 'Runing 5x N4 on FLASH Data'
for i in {1..5} 
do 

        current_iter_flash_1=${TISSUE_SEGMENTATION_DIR}/flash_contr1_N4_${i}x.nii.gz
        current_iter_flash_2=${TISSUE_SEGMENTATION_DIR}/flash_contr2_N4_${i}x.nii.gz
        current_iter_flash_3=${TISSUE_SEGMENTATION_DIR}/flash_contr3_N4_${i}x.nii.gz
        current_iter_flash_4=${TISSUE_SEGMENTATION_DIR}/flash_contr4_N4_${i}x.nii.gz
        current_iter_flash_5=${TISSUE_SEGMENTATION_DIR}/flash_contr5_N4_${i}x.nii.gz

        if [ $i == 1 ]
        then 
                previous_iter_flash_1=${TISSUE_SEGMENTATION_DIR}/flash_contr1.nii.gz
                previous_iter_flash_2=${TISSUE_SEGMENTATION_DIR}/flash_contr2.nii.gz
                previous_iter_flash_3=${TISSUE_SEGMENTATION_DIR}/flash_contr3.nii.gz
                previous_iter_flash_4=${TISSUE_SEGMENTATION_DIR}/flash_contr4.nii.gz
                previous_iter_flash_5=${TISSUE_SEGMENTATION_DIR}/flash_contr5.nii.gz
        else
                previous_iter_flash_1=${TISSUE_SEGMENTATION_DIR}/flash_contr1_N4_$( expr $i - 1 )x.nii.gz
                previous_iter_flash_2=${TISSUE_SEGMENTATION_DIR}/flash_contr2_N4_$( expr $i - 1 )x.nii.gz
                previous_iter_flash_3=${TISSUE_SEGMENTATION_DIR}/flash_contr3_N4_$( expr $i - 1 )x.nii.gz
                previous_iter_flash_4=${TISSUE_SEGMENTATION_DIR}/flash_contr4_N4_$( expr $i - 1 )x.nii.gz
                previous_iter_flash_5=${TISSUE_SEGMENTATION_DIR}/flash_contr5_N4_$( expr $i - 1 )x.nii.gz
        fi

        echo 'N4 FLASH Contrast 1: Run '${i}
        N4BiasFieldCorrection -d 3 \
                -i $previous_iter_flash_1 \
                -x ${TISSUE_SEGMENTATION_DIR}/mask.nii.gz \
                -o $current_iter_flash_1
        
        echo 'N4 FLASH Contrast 2: Run '${i}
        N4BiasFieldCorrection -d 3 \
                -i $previous_iter_flash_2 \
                -x ${TISSUE_SEGMENTATION_DIR}/mask.nii.gz \
                -o $current_iter_flash_2
        
        echo 'N4 FLASH Contrast 3: Run '${i}
        N4BiasFieldCorrection -d 3 \
                -i $previous_iter_flash_3 \
                -x ${TISSUE_SEGMENTATION_DIR}/mask.nii.gz \
                -o $current_iter_flash_3
        
        echo 'N4 FLASH Contrast 4: Run '${i}
        N4BiasFieldCorrection -d 3 \
                -i $previous_iter_flash_4 \
                -x ${TISSUE_SEGMENTATION_DIR}/mask.nii.gz \
                -o $current_iter_flash_4
        
        echo 'N4 FLASH Contrast 5: Run '${i}
        N4BiasFieldCorrection -d 3 \
                -i $previous_iter_flash_5 \
                -x ${TISSUE_SEGMENTATION_DIR}/mask.nii.gz \
                -o $current_iter_flash_5


done

echo 'Apply FLASH ANTS Warp to FLASH Data'

echo 'Apply warp to FLASH Contrast 1'
antsApplyTransforms \
	-d 3 \
	-i $current_iter_flash_1 \
	-r ${TISSUE_SEGMENTATION_DIR}/data_b0.nii.gz \
	-t ${FLASH_DIR_WARP}/flash_to_epi_1Warp.nii.gz \
	-t ${FLASH_DIR_WARP}/flash_to_epi_0GenericAffine.mat \
	-o ${TISSUE_SEGMENTATION_DIR}/flash_contr1_warp.nii.gz

echo 'Apply warp to FLASH Contrast 2'
antsApplyTransforms \
	-d 3 \
	-i $current_iter_flash_2 \
	-r ${TISSUE_SEGMENTATION_DIR}/data_b0.nii.gz \
	-t ${FLASH_DIR_WARP}/flash_to_epi_1Warp.nii.gz \
	-t ${FLASH_DIR_WARP}/flash_to_epi_0GenericAffine.mat \
	-o ${TISSUE_SEGMENTATION_DIR}/flash_contr2_warp.nii.gz

echo 'Apply warp to FLASH Contrast 3'
antsApplyTransforms \
	-d 3 \
	-i $current_iter_flash_3 \
	-r ${TISSUE_SEGMENTATION_DIR}/data_b0.nii.gz \
	-t ${FLASH_DIR_WARP}/flash_to_epi_1Warp.nii.gz \
	-t ${FLASH_DIR_WARP}/flash_to_epi_0GenericAffine.mat \
	-o ${TISSUE_SEGMENTATION_DIR}/flash_contr3_warp.nii.gz

echo 'Apply warp to FLASH Contrast 4'
antsApplyTransforms \
	-d 3 \
	-i $current_iter_flash_4 \
	-r ${TISSUE_SEGMENTATION_DIR}/data_b0.nii.gz \
	-t ${FLASH_DIR_WARP}/flash_to_epi_1Warp.nii.gz \
	-t ${FLASH_DIR_WARP}/flash_to_epi_0GenericAffine.mat \
	-o ${TISSUE_SEGMENTATION_DIR}/flash_contr4_warp.nii.gz

echo 'Apply warp to FLASH Contrast 5'
antsApplyTransforms \
	-d 3 \
	-i $current_iter_flash_5 \
	-r ${TISSUE_SEGMENTATION_DIR}/data_b0.nii.gz \
	-t ${FLASH_DIR_WARP}/flash_to_epi_1Warp.nii.gz \
	-t ${FLASH_DIR_WARP}/flash_to_epi_0GenericAffine.mat \
	-o ${TISSUE_SEGMENTATION_DIR}/flash_contr5_warp.nii.gz

echo 'Run fuzzy 2-class segmentation'
python3 ${SCRIPTS}/fuzzysegmentation.py \
	${TISSUE_SEGMENTATION_DIR}/mask.nii.gz \
	${TISSUE_SEGMENTATION_DIR}/dti_FA.nii.gz \
	${TISSUE_SEGMENTATION_DIR}/dti_MD.nii.gz \
	$current_iter_b0 \
	${TISSUE_SEGMENTATION_DIR}/flash_contr1_warp.nii.gz \
	${TISSUE_SEGMENTATION_DIR}/flash_contr2_warp.nii.gz \
	${TISSUE_SEGMENTATION_DIR}/flash_contr3_warp.nii.gz \
	${TISSUE_SEGMENTATION_DIR}/flash_contr4_warp.nii.gz \
	${TISSUE_SEGMENTATION_DIR}/flash_contr5_warp.nii.gz \
	${TISSUE_SEGMENTATION_DIR}/mask.nii.gz \
	${TISSUE_SEGMENTATION_DIR}'/' 2

echo 'Run fuzzy 3-class segmentation'
python3 ${SCRIPTS}/fuzzysegmentation.py \
	${TISSUE_SEGMENTATION_DIR}/mask.nii.gz \
	${TISSUE_SEGMENTATION_DIR}/dti_FA.nii.gz \
	${TISSUE_SEGMENTATION_DIR}/dti_MD.nii.gz \
	$current_iter_b0 \
	${TISSUE_SEGMENTATION_DIR}/flash_contr1_warp.nii.gz \
	${TISSUE_SEGMENTATION_DIR}/flash_contr2_warp.nii.gz \
	${TISSUE_SEGMENTATION_DIR}/flash_contr3_warp.nii.gz \
	${TISSUE_SEGMENTATION_DIR}/flash_contr4_warp.nii.gz \
	${TISSUE_SEGMENTATION_DIR}/flash_contr5_warp.nii.gz \
	${TISSUE_SEGMENTATION_DIR}/mask.nii.gz \
	${TISSUE_SEGMENTATION_DIR}'/' 3

echo 'Run fuzzy 4-class segmentation'
python3 ${SCRIPTS}/fuzzysegmentation.py \
	${TISSUE_SEGMENTATION_DIR}/mask.nii.gz \
	${TISSUE_SEGMENTATION_DIR}/dti_FA.nii.gz \
	${TISSUE_SEGMENTATION_DIR}/dti_MD.nii.gz \
	$current_iter_b0 \
	${TISSUE_SEGMENTATION_DIR}/flash_contr1_warp.nii.gz \
	${TISSUE_SEGMENTATION_DIR}/flash_contr2_warp.nii.gz \
	${TISSUE_SEGMENTATION_DIR}/flash_contr3_warp.nii.gz \
	${TISSUE_SEGMENTATION_DIR}/flash_contr4_warp.nii.gz \
	${TISSUE_SEGMENTATION_DIR}/flash_contr5_warp.nii.gz \
	${TISSUE_SEGMENTATION_DIR}/mask.nii.gz \
	${TISSUE_SEGMENTATION_DIR}'/' 4

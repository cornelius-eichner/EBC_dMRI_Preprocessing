#!/bin/bash

# Load Local Variables
source ./SET_VARIABLES.sh

# Copy nii files to topup directory
echo "Copy nii files to MNI reorient directory"
cp ${NII_RAW_DIR}/*X${CHECK_REORIENT_SCAN}P1.nii.gz ${REORIENT_DIR}/data.nii.gz


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
DATA_RESCALING_OLD=$DATA_RESCALING
DATA_RESCALING=$(${FSL_LOCAL}/fslstats ${REORIENT_DIR}/data_reshape.nii.gz -m)


DATA_RESCALING_STR_OLD="DATA_RESCALING=$DATA_RESCALING_OLD"
DATA_RESCALING_STR_NEW="DATA_RESCALING=$DATA_RESCALING"

# Saving mask string in set variables file
sed -i "s/$DATA_RESCALING_STR_OLD/$DATA_RESCALING_STR_NEW/gi" ./SET_VARIABLES.sh

mv -f ${REORIENT_DIR}/data_reshape.nii.gz ${REORIENT_DIR}/data_reshape_unscaled.nii.gz 

${FSL_LOCAL}/fslmaths ${REORIENT_DIR}/data_reshape_unscaled.nii.gz \
    -div ${DATA_RESCALING} \
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


echo $0 " Done" 
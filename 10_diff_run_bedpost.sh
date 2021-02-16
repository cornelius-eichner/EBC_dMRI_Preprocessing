#!/bin/bash

# Following FSL and CUDA Version need to be active
# CUDA --version 8.0
# FSL --version 5.0.11


# Load Local Variables
source ./SET_VARIABLES.sh

cp ${DIFF_DATA_DIR}/data_debias_denoise_detrend_eddy.nii.gz ${DIFF_DATA_BEDPOSTX_DIR}/data.nii.gz
cp ${DIFF_DATA_DIR}/mask.nii.gz 							${DIFF_DATA_BEDPOSTX_DIR}/nodif_brain_mask.nii.gz
cp ${DIFF_DATA_DIR}/data.bvals 								${DIFF_DATA_BEDPOSTX_DIR}/bvals
cp ${EDDY_DIR}/*bvecs		 								${DIFF_DATA_BEDPOSTX_DIR}/bvecs

bedpostx_gpu ${DIFF_DATA_BEDPOSTX_DIR}

echo 'done'
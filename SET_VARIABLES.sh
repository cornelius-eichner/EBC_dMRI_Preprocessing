#!/bin/bash

# This file needs to be copied in the preprocessing folder of each respective subject. Potential changes in processing should be made in this folder.

# Folder of Bruker Data in Bruker Format
BRUKER_RAW_DIR=/data/pt_02101_dMRI/027_C_W_FREDY_TAI_E/raw/20210317_150859_027_C_W_FREDY_TAI_E_1_1/

#########################################
# Select Scans for Processing

# Reorientation Check
CHECK_REORIENT_SCAN=12

# Noisemap
NOISE_SCAN=16

# Topup
TOPUP_LR_RUN=12
TOPUP_RL_RUN=15


# Diffusion Data
DIFF_SCANS=(12 18 19 20 21 22 23 24 25)
DATA_RESCALING=0.002042
MASK_THRESHOLD=0.25
HEAT_CORRECTION="NO" #YES/NO


# FLASH Scans
FLASH_FA_05=27
FLASH_FA_12p5=28
FLASH_FA_25=29
FLASH_FA_50=30
FLASH_FA_80=31
FLASH_HIGHRES=32
FLASH_ULTRA_HIGHRES=33

####################################



# Reorientation to MNI space
RESHAPE_ARRAY_ORD="1,0,2"
RESHAPE_ARRAY_INV="2"
RESHAPE_BVECS_ORD="1,0,2"
RES=0.5
HIGHRES=0.25
ULTRA_HIGHRES=0.15


# Eddy Parameters
N_DIRECTION="58"
TE="0.1"
PE_DIRECTION="1"


# Fetch file directory as Variable
LOCAL_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"


# Check the number of available cores for parallel processing
N_CORES=4

########################
# Local Folders for Processing
# Diffusion Data Folder Variables
DIFF_DIR="${LOCAL_DIR}/diff/"
DIFF_DATA_DIR="${DIFF_DIR}/data/"
DIFF_DATA_N4_DIR="${DIFF_DIR}/data_N4/"
DIFF_DATA_RELEASE_DIR="${DIFF_DIR}/data_release/"
DIFF_DATA_NORM_RELEASE_DIR="${DIFF_DIR}/data_release_norm/"
DIFF_DATA_BEDPOSTX_DIR="${DIFF_DIR}/data_bedpost/"
DTI_DIR=${DIFF_DIR}/dti
EDDY_DIR="${DIFF_DIR}/eddy/"
EDDY_FIELDS_DIR="${DIFF_DIR}/eddy_fields/"
EDDY_FIELDS_REL_DIR="${DIFF_DIR}/eddy_fields_rel/"
EDDY_FIELDS_JAC_DIR="${DIFF_DIR}/eddy_fields_jac/"
NII_RAW_DIR="${LOCAL_DIR}/nifti_raw/"
NOISEMAP_DIR="${DIFF_DIR}/noisemap/"
REORIENT_DIR="${DIFF_DIR}/mni_reorient_check/"
SPLIT_DIR=${DIFF_DATA_DIR}/split/
SPLIT_WARPED_DIR=${DIFF_DATA_DIR}/split_warped/
TOPUP_DIR="${DIFF_DIR}/topup/"

# FLASH Data Folder Variables
FLASH_DIR="${LOCAL_DIR}/flash/"
FLASH_DIR_FA05="${FLASH_DIR}/FA05/"
FLASH_DIR_FA12p5="${FLASH_DIR}/FA12p5/"
FLASH_DIR_FA25="${FLASH_DIR}/FA25/"
FLASH_DIR_FA50="${FLASH_DIR}/FA50/"
FLASH_DIR_FA80="${FLASH_DIR}/FA80/"
FLASH_DIR_HIGHRES="${FLASH_DIR}/HIGHRES/"
FLASH_DIR_ULTRA_HIGHRES="${FLASH_DIR}/ULTRA_HIGHRES/"

########################
# Set Scripts and Software Folders
SCRIPTS=${LOCAL_DIR}/scripts/
SOFTWARE=/data/pt_02101_dMRI/software/
FSL_LOCAL=/data/pt_02101_dMRI/software/fsl6/bin/
CONFIG_DIR=${LOCAL_DIR}/config/
EDDY_PATH=/data/pt_02101_dMRI/software/eddy/eddy_cuda8.0

########################
# Load Local CONDA Environment
eval "$(/data/pt_02101_dMRI/software/anaconda3/bin/conda shell.bash hook)"
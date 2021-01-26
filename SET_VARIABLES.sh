#!/bin/bash

# This file needs to be copied in the preprocessing folder of each respective subject. Potential changes in processing should be made in this folder.

# Folder of Bruker Data in Bruker Format
BRUKER_RAW_DIR='ENTER BRUKER DIR'

#########################################
# Select Scans for Processing

# Reorientation Check
CHECK_REORIENT_SCAN='ENTER SINGLE VOLUME NUMBER FOR REORIENTATION CHECK'

# Noisemap
NOISE_SCAN='ENTER NOISEMAP NUMBER'

# Topup
TOPUP_LR_RUN='ENTER TOPUP LR NUMBER'
TOPUP_RL_RUN='ENTER TOPUP RL NUMBER'


# Diffusion Data
DIFF_SCANS='ENTER DIFFUSION SCANS NUMBER e.g., (18 35 22 23 24 25 26 27 28)'
DATA_RESCALING="10000"
MASK_THRESHOLD="50"
HEAT_CORRECTION="NO" #YES/NO


# FLASH Scans
FLASH_FA_05=29
FLASH_FA_12p5=30
FLASH_FA_25=31
FLASH_FA_50=32
FLASH_FA_80=33
FLASH_HIGHRES=31

####################################



# Reorientation to MNI space
RESHAPE_ARRAY_ORD="1,0,2"
RESHAPE_ARRAY_INV="2"
RES="0.5"
RESHAPE_BVECS_ORD="1,0,2"


# Eddy Parameters
N_DIRECTION="58"
TE="0.1"
PE_DIRECTION="1"


# Fetch file directory as Variable
LOCAL_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

########################
# Local Folders for Processing

# Diffusion Data Folder Variables
DIFF_DIR="${LOCAL_DIR}/diff/"
DIFF_DATA_DIR="${DIFF_DIR}/data/"
DIFF_DATA_N4_DIR="${DIFF_DIR}/data_N4/"
DIFF_DATA_RELEASE_DIR="${DIFF_DIR}/data_release/"
DIFF_DATA_NORM_RELEASE_DIR="${DIFF_DIR}/data_release_norm/"
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

########################
# Set Scripts and Software Folders
SCRIPTS=${LOCAL_DIR}/scripts/
SOFTWARE=/data/pt_02101_dMRI/software/
FSL_LOCAL=/data/pt_02101_dMRI/software/fsl6/bin/
CONFIG_DIR=/data/pt_02101_dMRI/config/
EDDY_PATH=/data/pt_02101_dMRI/software/eddy/eddy_openmp

########################
# Load Local CONDA Environment
eval "$(/data/pt_02101_dMRI/software/anaconda3/bin/conda shell.bash hook)"

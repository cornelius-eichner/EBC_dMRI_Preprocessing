#!/bin/bash

# This file needs to be copied in the preprocessing folder of each respective subject. Potential changes in processing should be made in this folder.

# Folder of Bruker Data in Bruker Format
BRUKER_RAW_DIR=/data/pt_02101_dMRI/007_C_C_NEGRA_ID/raw/210217_BioSpec9430_Bremerhaven_WB/20210217_151226_007_C_C_NEGRA_ID11357_1_2/

#########################################
# Select Scans for Processing

# Reorientation Check
CHECK_REORIENT_SCAN=8

# Noisemap
NOISE_SCAN=10

# Topup
TOPUP_LR_RUN=8
TOPUP_RL_RUN=9


# Diffusion Data
DIFF_SCANS=(8 12 13 14 15 16 17 30 19)
DATA_RESCALING="10000"
MASK_THRESHOLD=4.2
HEAT_CORRECTION="NO" #YES/NO


# FLASH Scans
FLASH_FA_05=21
FLASH_FA_12p5=22
FLASH_FA_25=23
FLASH_FA_50=24
FLASH_FA_80=25
FLASH_HIGHRES=26
FLASH_ULTRA_HIGHRES=31

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


# Check the number of available cores for parallel processing
N_CORES=$(nproc --all)

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
FLASH_DIR_ULTRA_HIGHRES="${FLASH_DIR}/ULTRA_HIGHRES/"

########################
# Set Scripts and Software Folders
SCRIPTS=${LOCAL_DIR}/scripts/
SOFTWARE=/data/pt_02101_dMRI/software/
FSL_LOCAL=/data/pt_02101_dMRI/software/fsl6/bin/
CONFIG_DIR=/data/pt_02101_dMRI/config/
EDDY_PATH=/data/pt_02101_dMRI/software/eddy/eddy_cuda8.0

########################
# Load Local CONDA Environment
eval "$(/data/pt_02101_dMRI/software/anaconda3/bin/conda shell.bash hook)"

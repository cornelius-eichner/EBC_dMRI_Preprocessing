#!/bin/bash

# Load Local Variables
source ./SET_VARIABLES.sh

# Generate Diffusion Folders
mkdir -p \
	${DIFF_DIR} \
	${DIFF_DATA_DIR} \
	${DIFF_DATA_N4_DIR} \
	${DIFF_DATA_NORM_DIR} \
	${DIFF_DATA_NORM_RELEASE_DIR} \
	${DIFF_DATA_RELEASE_DIR} \
	${DIFF_DATA_BEDPOSTX_DIR} \
	${DTI_DIR} \
	${EDDY_DIR} \
	${EDDY_FIELDS_DIR} \
	${EDDY_FIELDS_REL_DIR} \
	${EDDY_FIELDS_JAC_DIR} \
	${NII_RAW_DIR} \
	${NOISEMAP_DIR} \
	${REORIENT_DIR} \
	${SPLIT_DIR} \
	${SPLIT_WARPED_DIR} \
	${TOPUP_DIR} 


# Generate FLASH FOLDERS
mkdir -p  \
	${FLASH_DIR} \
	${FLASH_DIR_FA05} \
	${FLASH_DIR_FA12p5} \
	${FLASH_DIR_FA25} \
	${FLASH_DIR_FA50} \
	${FLASH_DIR_FA80} \
	${FLASH_DIR_HIGHRES} \
	${FLASH_DIR_ULTRA_HIGHRES} 


echo $0 " Done" 
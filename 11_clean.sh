#!/bin/bash

# Following FSL and CUDA Version need to be active
# CUDA --version 8.0
# FSL --version 5.0.11


# Load Local Variables
source ./SET_VARIABLES.sh

echo "Removing intermedidate calculation folders"

rm -rf \
	${DIFF_DATA_N4_DIR} \
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


echo $0 " Done" 
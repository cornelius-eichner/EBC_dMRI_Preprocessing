#!/bin/bash

# Load Local Variables
source ./SET_VARIABLES.sh

# Convert Bruker Data to Nifti
${SOFTWARE}/bru2/Bru2 -a -p -z -v ${BRUKER_RAW_DIR}/subject
mv ${BRUKER_RAW_DIR}/*.nii.gz ${NII_RAW_DIR}


echo $0 " Done" 
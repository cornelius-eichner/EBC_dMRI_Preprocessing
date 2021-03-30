#!/bin/bash

# Load Local Variables
source ./SET_VARIABLES.sh

# Copy nii files to topup directory
echo "Copy nii files to respective directories"

#FA 5 deg
cp ${NII_RAW_DIR}/*X${FLASH_FA_05}P1.nii.gz ${FLASH_DIR_FA05}/data.nii.gz

#FA 12.5 deg
cp ${NII_RAW_DIR}/*X${FLASH_FA_12p5}P1.nii.gz ${FLASH_DIR_FA12p5}/data.nii.gz

#FA 25 deg
cp ${NII_RAW_DIR}/*X${FLASH_FA_25}P1.nii.gz ${FLASH_DIR_FA25}/data.nii.gz

#FA 50 deg
cp ${NII_RAW_DIR}/*X${FLASH_FA_50}P1.nii.gz ${FLASH_DIR_FA50}/data.nii.gz

#FA 80 deg
cp ${NII_RAW_DIR}/*X${FLASH_FA_80}P1.nii.gz ${FLASH_DIR_FA80}/data.nii.gz

#Highres
cp ${NII_RAW_DIR}/*X${FLASH_HIGHRES}P1.nii.gz ${FLASH_DIR_HIGHRES}/data.nii.gz

#Ultra Highres
cp ${NII_RAW_DIR}/*X${FLASH_ULTRA_HIGHRES}P1.nii.gz ${FLASH_DIR_ULTRA_HIGHRES}/data.nii.gz


# Reshape image matrix to resemble MNI space
echo "Reshape image matrix to resemble MNI space"
python3 ${SCRIPTS}/reshape_volume.py \
	--in ${FLASH_DIR_FA05}/data.nii.gz \
	--out ${FLASH_DIR_FA05}/data_reshape.nii.gz \
	--ord ${RESHAPE_ARRAY_ORD} \
	--inv ${RESHAPE_ARRAY_INV} \
	--res ${RES}

python3 ${SCRIPTS}/reshape_volume.py \
	--in ${FLASH_DIR_FA12p5}/data.nii.gz \
	--out ${FLASH_DIR_FA12p5}/data_reshape.nii.gz \
	--ord ${RESHAPE_ARRAY_ORD} \
	--inv ${RESHAPE_ARRAY_INV} \
	--res ${RES}

python3 ${SCRIPTS}/reshape_volume.py \
	--in ${FLASH_DIR_FA25}/data.nii.gz \
	--out ${FLASH_DIR_FA25}/data_reshape.nii.gz \
	--ord ${RESHAPE_ARRAY_ORD} \
	--inv ${RESHAPE_ARRAY_INV} \
	--res ${RES}

python3 ${SCRIPTS}/reshape_volume.py \
	--in ${FLASH_DIR_FA50}/data.nii.gz \
	--out ${FLASH_DIR_FA50}/data_reshape.nii.gz \
	--ord ${RESHAPE_ARRAY_ORD} \
	--inv ${RESHAPE_ARRAY_INV} \
	--res ${RES}

python3 ${SCRIPTS}/reshape_volume.py \
	--in ${FLASH_DIR_FA80}/data.nii.gz \
	--out ${FLASH_DIR_FA80}/data_reshape.nii.gz \
	--ord ${RESHAPE_ARRAY_ORD} \
	--inv ${RESHAPE_ARRAY_INV} \
	--res ${RES}

python3 ${SCRIPTS}/reshape_volume.py \
	--in ${FLASH_DIR_HIGHRES}/data.nii.gz \
	--out ${FLASH_DIR_HIGHRES}/data_reshape.nii.gz \
	--ord ${RESHAPE_ARRAY_ORD} \
	--inv ${RESHAPE_ARRAY_INV} \
	--res ${HIGHRES}

python3 ${SCRIPTS}/reshape_volume.py \
	--in ${FLASH_DIR_ULTRA_HIGHRES}/data.nii.gz \
	--out ${FLASH_DIR_ULTRA_HIGHRES}/data_reshape.nii.gz \
	--ord ${RESHAPE_ARRAY_ORD} \
	--inv ${RESHAPE_ARRAY_INV} \
	--res ${ULTRA_HIGHRES}


mv -f ${FLASH_DIR_FA05}/data_reshape.nii.gz ${FLASH_DIR_FA05}/data.nii.gz
mv -f ${FLASH_DIR_FA12p5}/data_reshape.nii.gz ${FLASH_DIR_FA12p5}/data.nii.gz
mv -f ${FLASH_DIR_FA25}/data_reshape.nii.gz ${FLASH_DIR_FA25}/data.nii.gz
mv -f ${FLASH_DIR_FA50}/data_reshape.nii.gz ${FLASH_DIR_FA50}/data.nii.gz
mv -f ${FLASH_DIR_FA80}/data_reshape.nii.gz ${FLASH_DIR_FA80}/data.nii.gz
mv -f ${FLASH_DIR_HIGHRES}/data_reshape.nii.gz ${FLASH_DIR_HIGHRES}/data.nii.gz
mv -f ${FLASH_DIR_ULTRA_HIGHRES}/data_reshape.nii.gz ${FLASH_DIR_ULTRA_HIGHRES}/data.nii.gz


# Show reoriented data alongside with MNI brain
mrview \
	-load ${FLASH_DIR_FA25}/data.nii.gz \
	-interpolation 0  \
	-mode 2 &

mrview \
	-load /data/pt_02101_dMRI/software/fsl6/data/standard/MNI152_T1_1mm_brain.nii.gz \
	-interpolation 0 \
	-mode 2 &


echo $0 " Done"
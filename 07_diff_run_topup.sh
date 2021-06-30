#!/bin/bash

# Load Local Variables
source ./SET_VARIABLES.sh
source ${FSL_LOCAL}/etc/fslconf/fsl.sh



# Copy nii files to topup directory
echo "Copy nii files to topup directory"
cp ${NII_RAW_DIR}/*X${TOPUP_LR_RUN}P1.nii.gz ${TOPUP_DIR}/data_LR.nii.gz

if [ $FLAG_TOPUP_RETRO_RECON == "NO" ]; then
    cp ${NII_RAW_DIR}/*X${TOPUP_RL_RUN}P1.nii.gz ${TOPUP_DIR}/data_RL.nii.gz

elif [[ $FLAG_TOPUP_RETRO_RECON == "YES" ]]; then
    cp ${NII_RAW_DIR}/*X${TOPUP_RL_RUN}P${RETRO_RECON_NUMBER}.nii.gz ${TOPUP_DIR}/data_RL.nii.gz

else
    echo 'Please Specify $FLAG_TOPUP_RETRO_RECON'
fi

# Reshape image matrix to resemble MNI space
echo "Reshape image matrix to resemble MNI space"
python3 ${SCRIPTS}/reshape_volume.py \
    --in ${TOPUP_DIR}/data_LR.nii.gz \
    --out ${TOPUP_DIR}/data_LR_reshape.nii.gz \
    --ord ${RESHAPE_ARRAY_ORD} \
    --inv ${RESHAPE_ARRAY_INV} \
    --res ${RES}

python3 ${SCRIPTS}/reshape_volume.py \
    --in ${TOPUP_DIR}/data_RL.nii.gz \
    --out ${TOPUP_DIR}/data_RL_flipped.nii.gz \
    --ord ${RESHAPE_ARRAY_ORD} \
    --inv ${RESHAPE_ARRAY_INV} \
    --res ${RES}

python3 ${SCRIPTS}/reshape_volume.py \
    --in ${TOPUP_DIR}/data_RL_flipped.nii.gz \
    --out ${TOPUP_DIR}/data_RL_reshape.nii.gz \
    --ord 0,1,2 \
    --inv 0 \
    --res ${RES}


# Correct for shift along x axis of RL-data
echo "Correct for shift along x axis of RL-data"
python3 ${SCRIPTS}/roll_align_data.py \
    --in ${TOPUP_DIR}/data_RL_reshape.nii.gz \
    --ref ${TOPUP_DIR}/data_LR_reshape.nii.gz \
    --out ${TOPUP_DIR}/data_RL_reshape_shift.nii.gz \
    --axis 0


echo "Combine the corrected data"
${FSL_LOCAL}/fslmerge -t \
    ${TOPUP_DIR}/data.nii.gz \
    ${TOPUP_DIR}/data_LR_reshape.nii.gz \
    ${TOPUP_DIR}/data_RL_reshape_shift.nii.gz


echo "Runing Multiple N4 on dMRI b0 Data"
for i in $(seq 1 $N4_ITER)
do 
        CURRENT_ITER_B0=${TOPUP_DIR}/data_N4_${i}x.nii.gz

        if [ $i == 1 ]
        then 
                PREVIOUS_ITER_B0=${TOPUP_DIR}/data.nii.gz
        else
                PREVIOUS_ITER_B0=${TOPUP_DIR}/data_N4_$( expr $i - 1 )x.nii.gz
        fi

        echo 'N4 b0 dMRI: Run '${i}

        N4BiasFieldCorrection -d 4 \
                -i ${PREVIOUS_ITER_B0} \
                -o ${CURRENT_ITER_B0}
done


# Display Topup Corrected Data
echo "Show Data for Topup"
mrview \
    -load ${CURRENT_ITER_B0} \
    -interpolation 0 \
    -mode 2 &


# Run Topup Algorithm
echo "Run Topup Algorithm"
${FSL_LOCAL}/topup \
    --imain=${CURRENT_ITER_B0} \
    --datain=${CONFIG_DIR}/topup/acqp \
    --config=${CONFIG_DIR}/topup/b02b0.cnf \
    --out=${TOPUP_DIR}/topup \
    --fout=${TOPUP_DIR}/topup_field.nii.gz \
    --iout=${TOPUP_DIR}/data_unwarp.nii.gz \
    -v 

# Display Topup Corrected Data
echo "Show Corrected Data"
mrview \
    -load ${CURRENT_ITER_B0} \
    -interpolation 0 \
    -load ${TOPUP_DIR}/data_unwarp.nii.gz \
    -interpolation 0 \
    -load ${TOPUP_DIR}/topup_field.nii.gz \
    -interpolation 0 \
    -mode 2 &


echo $0 " Done" 
# EBC dMRI Preprocessing
Scripted processing of the post-mortem chimpanzee diffusion MRI (dMRI) dataset acquired within the framework of the Evolution of Brain Connectivity (EBC) project. 

## Input
- DMRI EBC Dataset in Bruker PV 6.0.1 File structure
- High-Resolution FLASH Dataset in PV File structure

## Output
- Processed dMRI Datasets
  - Reorientation to MNI-Like Space
  - Noise Bias Removal and MP PCA Denoising 
  - TOPUP and Motion Correction 
  - DTI Fit

## Requirements
- FSL incl eddy_cuda
- MRTRIX
- ANTS
- Python 3 incl Numpy, Nibabel, SciPy, DiPy

## How to Use
- All processing variables can be modified in the 'SET_VARIABLES.sh' file.
- The preprocessing will only run in sequential order of the supplied files, as multiple processing steps rely on results from previous processing steps. 

### Application of Processing
1. Clone the GitHub repository into the preprocessing folder 
2. Enter the absolute path of the raw Bruker files in the 'BRUKER_RAW_DIR' variable
3. Run scripts '1_make_folders.sh', '2_make_nii.sh', '3_make_scanlist.sh' to generate the required folder structure, Nifti files and 'Scanlist.txt'
4. Modify the 'CHECK_REORIENT_SCAN' variable to match the Scan list number of a single volume scan and run the script '4_check_reorientation.sh'. If the reoriented image resembles an MNI oriented brain image, proceed. Otherwise, modify the variables noted under "Reorientation to MNI Space"
5. Run script '5_flash_load_data.sh' to unpack and name the FLASH data
6. Run script '6_diff_run_noise_characterization.sh' to analyze the acquired noise-map
7. Run script '7_diff_run_topup.sh' to calculate the TopUp distortion correction. The TopUp warp field will not be applied directly to the data but combined with the other distortion fields in the dMRI processing step. 
8. Run script '8_diff_run_preprocess.sh' to preprocess the dMRI data, using the previously calculated results. 

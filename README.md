# EBC Diffusion MRI Preprocessing
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
* FSL incl eddy_cuda
* MRTRIX
* ANTS
* Python 3 incl following libraries: 
	* [Numpy](https://pypi.org/project/numpy/)
	* [Nibabel](https://pypi.org/project/nibabel/) 
	* [SciPy](https://pypi.org/project/scipy/)
	* [DiPy](https://pypi.org/project/dipy/)
	* [autodmri>=0.2.5](https://pypi.org/project/autodmri/)
* Bru2Nii for Bruker Data Conversion

## How to Use
- All processing variables can be modified in the 'SET_VARIABLES.sh' file.
- The preprocessing will only run in sequential order of the supplied files, as multiple processing steps rely on results from previous processing steps. 

### Application of Processing
1. Clone the GitHub repository into the preprocessing folder 
2. Enter the absolute path of the raw Bruker files in the 'BRUKER_RAW_DIR' variable
3. Run scripts '01_make_folders.sh', '02_make_nii.sh', '03_make_scanlist.sh' to generate the required folder structure, Nifti files and 'Scanlist.txt'
4. Run the script '04_check_reorientation.sh'. If the reoriented image resembles an MNI oriented brain image, proceed. Otherwise, modify the variables noted under "Reorientation to MNI Space"
5. Run script '05_flash_load_data.sh' to unpack and name the FLASH data
6. Run script '06_diff_run_noise_characterization.sh' to analyze the acquired noise-map
7. Run script '07_diff_run_topup.sh' to calculate the TopUp distortion correction. The TopUp warp field will not be applied directly to the data but combined with the other distortion fields in the dMRI processing step. 
8. Run script '08_diff_load_prep.sh' and '09_diff_run_preprocess.sh' to load adn preprocess the dMRI data, using the previously calculated results. Make sure to have CUDA activated.
9. Run script '10_diff_run_bedpost.sh' to run bedpostX. Make sure to have CUDA activated. 

### Disclaimer
Important Notice: This software package is intended solely for research purposes within the field of medical imaging. Any use of this software for medical diagnostics, treatment, or any non-research purposes is strictly prohibited. By accessing, downloading, or using this software, you agree to abide by these terms. Please also read Licesing information. 

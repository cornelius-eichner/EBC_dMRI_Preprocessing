#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import argparse 
import nibabel as nib
import numpy as np
import os
from scipy import interp


DESCRIPTION =   'Drift Correction of dMRI Data, Based on Linear Interpolation Between b0s. Cornelius Eichner 2021'

def buildArgsParser():
    p = argparse.ArgumentParser(description=DESCRIPTION)
    p.add_argument('--in', dest='input', action='store', type=str,
                            help='Input Data Path')
    
    p.add_argument('--mask', dest='mask', action='store', type=str,
                                help='Mask Path')

    p.add_argument('--bval', dest='bval', action='store', type=str,
                            help='BVALS Path')

    p.add_argument('--out', dest='out', action='store', type=str,
                            help='Output Path')

    return p


def main():

    # Load parser to read data from command line input
    parser = buildArgsParser()
    args = parser.parse_args()

    # Load input variables
    PATH_IN     = os.path.realpath(args.input)
    PATH_MASK     = os.path.realpath(args.mask)
    PATH_BVAL    = os.path.realpath(args.bval)
    PATH_OUT    = os.path.realpath(args.out) 

    # Load Data
    print('Loading Data')
    data = nib.load(PATH_IN).get_fdata().astype(np.float32)
    aff = nib.load(PATH_IN).affine
    dims = data.shape

    mask = nib.load(PATH_MASK).get_fdata().astype(np.bool)

    bvals = np.round(np.genfromtxt(PATH_BVAL), -3).squeeze()


    print('Running Drift Correction')

    b0_mask = bvals == 0
    b0_idx = np.where(bvals == 0)[0]

    # Calculate B0 mean 
    data_mean = data[mask,:].mean(axis = 0)
    b0_mean = data_mean[b0_mask].mean()

    # Interpolate between b0 images
    data_idx = np.linspace(0, data_mean.shape[0]-1, data_mean.shape[0], dtype = np.int) 
    b0_interp = interp(x = data_idx, xp = b0_idx, fp = data_mean[b0_idx])

    data_drift_corr = b0_mean * ( data[..., :] / b0_interp )


    # Save Data
    print('Saving Data')

    nib.save(nib.Nifti1Image(np.clip(data_drift_corr, 0, np.inf), aff), PATH_OUT)


if __name__ == '__main__':
    main()

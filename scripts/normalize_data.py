#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import argparse 
import nibabel as nib
import numpy as np
import os


DESCRIPTION =   'DMRI Data Normalization with B0 image and calculation of Spherical Mean Image. Cornelius Eichner 2020'
FSL_LOCAL = '/data/pt_02101_dMRI/software/fsl6/bin/'

def buildArgsParser():
    p = argparse.ArgumentParser(description=DESCRIPTION)
    p.add_argument('--in', dest='input', action='store', type=str,
                            help='Input Data Path')

    p.add_argument('--in_sigma', dest='input_sigma', action='store', type=str,
                            help='Input sigma Path')

    p.add_argument('--in_N', dest='input_N', action='store', type=str,
                            help='Input N Path')
    
    p.add_argument('--mask', dest='mask', action='store', type=str,
                                help='Mask Path')

    p.add_argument('--bval', dest='bval', action='store', type=str,
                            help='BVALS Path')

    p.add_argument('--bvec', dest='bvec', action='store', type=str,
                            help='BVALS Path')

    p.add_argument('--out_folder', dest='out_fol', action='store', type=str,
                            help='Output Path')

    return p


def main():

    # Load parser to read data from command line input
    parser = buildArgsParser()
    args = parser.parse_args()

    # Load input variables
    PATH_IN     = os.path.realpath(args.input)
    PATH_SIGMA  = os.path.realpath(args.input_sigma)
    PATH_N      = os.path.realpath(args.input_N)
    PATH_MASK   = os.path.realpath(args.mask)
    PATH_BVAL   = os.path.realpath(args.bval)
    PATH_BVEC   = os.path.realpath(args.bvec)
    PATH_OUT    = os.path.realpath(args.out_fol) + '/'

    # Load Data
    print('Loading Data')
    data = nib.load(PATH_IN).get_fdata()
    aff = nib.load(PATH_IN).affine
    dims = data.shape

    sigmas = nib.load(PATH_SIGMA).get_fdata()
    Ns = nib.load(PATH_N).get_fdata()

    mask = nib.load(PATH_MASK).get_fdata().astype(np.bool)

    bvals = np.genfromtxt(PATH_BVAL)
    bvecs = np.genfromtxt(PATH_BVEC)

    if bvecs.shape[1] == 3:
        bvecs = bvecs.transpose()

    bvals_round = np.round(bvals, -3) # Round to the nearest 1000

    bvals_shells = np.unique(bvals_round[bvals_round > 0])

    b0_mask = bvals_round == 0

    # Calculate B0 mean 
    data_b0_mean = data[..., b0_mask].mean(axis = 3)

    print('Normalizing Data')
    # Go through Shells
    if len(bvals_shells) > 1:
        # TODO
        print('Current Version of Script only works with single shell data.')
    elif len(bvals_shells) < 1:
        print('No Diffusion Shells Found in privided data.')
    elif len(bvals_shells == 1):
        diff_mask = bvals_round != 0

        # Normalize Data
        data_norm = np.clip(mask[..., None] * (data[..., diff_mask] / data_b0_mean[..., None]), 0, 1)
        # Concatenate mask as fake normalized b0
        data_norm = np.concatenate((mask.astype(np.float)[...,None], data_norm), axis=3)


        # Clean Data from unwanted values
        data_norm[np.isnan(data_norm)] = 0
        data_norm[np.isinf(np.abs(data_norm))] = 0

        # Spherical Mean Calculation
        data_norm_mean = data_norm.mean(axis = 3)
        data_norm_std = data_norm.std(axis = 3)

        bvals_norm = bvals[diff_mask]
        bvals_norm = np.concatenate(([0], bvals_norm), axis=0)
        bvecs_norm = bvecs[:, diff_mask]
        bvecs_norm = np.concatenate(([[0],[0],[0]], bvecs_norm), axis=1)


    # compute stable sigma estimation and normalize
    sigma_stable = sigmas*Ns / np.mean(Ns)
    sigma_norm = sigma_stable / data_b0_mean

    # cleanup sigma
    sigma_norm[~mask] = 0
    sigma_norm[np.isnan(sigma_norm)] = 0
    sigma_norm[np.isinf(sigma_norm)] = 0


    # Save Data
    print('Saving Data')
    nib.save(nib.Nifti1Image(np.clip(data_norm, 0, 1).astype(np.float32), aff), PATH_OUT + 'data_norm.nii.gz')
    nib.save(nib.Nifti1Image(np.clip(data_norm_mean, 0, 1).astype(np.float32), aff), PATH_OUT + 'data_norm_mean.nii.gz')
    nib.save(nib.Nifti1Image(np.clip(data_norm_std, 0, 1).astype(np.float32), aff), PATH_OUT + 'data_norm_std.nii.gz')
    nib.save(nib.Nifti1Image(np.clip(sigma_norm, 0, 1).astype(np.float32), aff), PATH_OUT + 'sigma_norm.nii.gz')
    
    np.savetxt(PATH_OUT + 'data_norm.bval', bvals_norm, fmt = '%.5f')
    np.savetxt(PATH_OUT + 'data_norm.bvec', bvecs_norm, fmt = '%.5f')


if __name__ == '__main__':
    main()

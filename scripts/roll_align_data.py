#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import argparse
import numpy as np
import nibabel as nib
import pylab as plt
import os


DESCRIPTION =   """
Align Shifted LR and RL Data for TopUp using only axis roll. 
This step is required due to a shift on Bruker scanners if the PE direction is reversed. 
Cornelius Eichner 2020"""

np.set_printoptions(precision=2)

def buildArgsParser():
    p = argparse.ArgumentParser(description=DESCRIPTION)
    p.add_argument('--in', dest='input', action='store', type=str,
                            help='Name of the input nii file')

    p.add_argument('--ref', dest='reference', action='store', type=str,
                            help='Name of the reference nii file')

    p.add_argument('--out', dest='output', action='store', type=str,
                            help='Name of the shifted output file')

    p.add_argument('--axis', dest='axis', action='store', type=int,
                            help='Name of the shifted output file')

    return p


def rmsd(X, Y):
    return np.sqrt(np.sum( (X.ravel() - Y.ravel())**2 ))

def main():
    # Load parser to read data from command line input
    parser = buildArgsParser()
    args = parser.parse_args()

    # Load input variables
    PATH_IN = os.path.realpath(args.input)
    PATH_REF = os.path.realpath(args.reference)
    PATH_OUT = os.path.realpath(args.output)
    AXIS=args.axis

    print("Loading Data")
    data_in = nib.load(PATH_IN).get_fdata()
    data_ref = nib.load(PATH_REF).get_fdata()
    aff  = nib.load(PATH_REF).affine
    dims = nib.load(PATH_REF).shape


    print("Rolling Array to Find Best Overlap")
    rmsd_per_roll = np.zeros(dims[AXIS])

    for i_x in range(dims[AXIS]):
        rmsd_per_roll[i_x] = rmsd(data_ref, np.roll(data_in, i_x, axis = AXIS))
        if not(i_x % 10):
            print(i_x)


    opt_roll = np.argmin(rmsd_per_roll)


    plt.figure()
    plt.title('Image Difference Depending on Roll')
    plt.plot(np.linspace(0, dims[AXIS]-1, dims[AXIS]), rmsd_per_roll)
    plt.plot(opt_roll, rmsd_per_roll[opt_roll], 'o')
    plt.show()


    data_in_shift = np.roll(data_in, opt_roll, axis = AXIS)


    print("Saving Rolled Data")
    nib.nifti1.Nifti1Image(data_in_shift, aff).to_filename(PATH_OUT)

if __name__ == '__main__':
    main()

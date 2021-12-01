#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import argparse 
import nibabel as nib
import numpy as np
import os
from scipy import interp


DESCRIPTION = """
Drift Correction of dMRI Data, Based on Linear Interpolation Between b0s
"""


EPILOG = """
Created by Cornelius Eichner, MPI CBS, 2021.
Updated with timestamps by Michael Paquette, MPI CBS, 2021.
"""


class CustomFormatter(argparse.ArgumentDefaultsHelpFormatter, argparse.RawTextHelpFormatter):
    pass


def buildArgsParser():
    p = argparse.ArgumentParser(description=DESCRIPTION,
                                epilog=EPILOG,
                                formatter_class=CustomFormatter)
    p.add_argument('--in', dest='input', action='store', type=str,
                            help='Input Data Path')
    
    p.add_argument('--mask', dest='mask', action='store', type=str,
                                help='Mask Path')

    p.add_argument('--bval', dest='bval', action='store', type=str,
                            help='BVALS Path')

    p.add_argument('--time', dest='timestamp', action='store', type=str,
                            help='Timestamps Path')

    p.add_argument('--out', dest='out', action='store', type=str,
                            help='Output Path')

    return p


def main():

    # Load parser to read data from command line input
    parser = buildArgsParser()
    args = parser.parse_args()

    # Load input variables
    PATH_IN     = os.path.realpath(args.input)
    PATH_MASK   = os.path.realpath(args.mask)
    PATH_BVAL   = os.path.realpath(args.bval)
    PATH_TIME   = os.path.realpath(args.timestamp)
    PATH_OUT    = os.path.realpath(args.out) 

    # Load Data
    print('Loading Data')
    data = nib.load(PATH_IN).get_fdata().astype(np.float32)
    aff = nib.load(PATH_IN).affine
    dims = data.shape

    mask = nib.load(PATH_MASK).get_fdata().astype(np.bool)

    bvals = np.genfromtxt(PATH_BVAL)

    timestamps = np.genfromtxt(PATH_TIME, dtype=np.int)


    print('Running Drift Correction')

    b0_mask = bvals == 0
    b0_idx = np.where(bvals < 0.01)[0]

    # print('b0 index: {}'.format(b0_idx))

    # timestamps of b0s
    x_ = timestamps[b0_idx]
    A_ = np.vstack([x_, np.ones(len(x_))]).T

    # Calculate B0 mean 
    data_mean = data[mask].mean(axis=0)

    # fit slope m_ and y-intercept c_
    m_, c_ = np.linalg.lstsq(A_, data_mean[b0_idx], rcond=None)[0]

    # correction = (m*x_prime + c) / (m*0 + c) = (m*x_prime / c) + 1
    drift_scaling = ((timestamps*m_) / c_) + 1
    data_drift_corr = data[..., :] / drift_scaling

    # import pylab as pl 
    # pl.figure()
    # pl.subplot(1,2,1)
    # pl.plot(timestamps, m_*timestamps + c_)
    # pl.scatter(x_, data_mean[b0_idx])
    # pl.title('Fit on B0s')
    # pl.subplot(1,2,2)
    # pl.semilogy(timestamps, data_mean, label='before', alpha=0.5)
    # pl.semilogy(timestamps, data_drift_corr[mask].mean(axis=0), label='after', alpha=0.5)
    # pl.legend()
    # pl.title('Drift correction on data')
    # pl.show()


    # Save Data
    print('Saving Data')

    nib.save(nib.Nifti1Image(np.clip(data_drift_corr, 0, np.inf), aff), PATH_OUT)


if __name__ == '__main__':
    main()

#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import argparse
import numpy as np
import nibabel as nib
import pylab as plt


DESCRIPTION = """
Plot the timeseries of a 4D Nifti file
"""

def buildArgsParser():
    p = argparse.ArgumentParser(description=DESCRIPTION)
    p.add_argument('--in', dest='input', action='store', type=str,
                            help='Path of the volume (nifti format)')

    p.add_argument('--mask', metavar='',
                             help='Path to a binary mask (nifti format)')

    return p


def main():
    parser = buildArgsParser()
    args = parser.parse_args()

    # enforcing 3D data
    datapath = args.input
    data = nib.load(datapath).get_fdata()

    if data.ndim != 4:
        print('Data is not 4D, terminating')
        return 0

    if args.mask is None:
        mask = np.ones(data.shape[:3]).astype(np.bool)
    else:
        mask = nib.load(args.mask).get_fdata().astype(np.bool)

    # Casting data as float
    data = data.astype(np.float)
    print('Data shape is {}'.format(data.shape))
    print('Mask shape is {}'.format(mask.shape))

    # Check mask dimensions
    if data.shape[:3] != mask.shape:
        print('Data and mask dimensions do not match, terminating')
        return 0

    data_mean = data[mask,:].mean(axis = 0) # Calculate the mean time sigal within the mask 

    # Plot timeseries
    plt.figure()
    plt.plot(data_mean)
    plt.grid('minor')
    plt.title('Mean Signal Across Time')
    plt.xlabel('Volume')
    plt.ylabel('Signal')
    plt.show()

if __name__ == '__main__':
    main()

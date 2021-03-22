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
    
    p.add_argument('--bvals', dest='bvals', action='store', type=str,
                             help='Path to a bvals file')

    p.add_argument('--out', dest='out', action='store', type=str,
                             help='Output path to save txt file with volume means')

    return p


def main():
    parser = buildArgsParser()
    args = parser.parse_args()

    datapath = args.input
    data = nib.load(datapath).get_fdata()

    # enforcing 4D data
    if data.ndim != 4:
        print('Data is not 4D, terminating')
        return 0

    if args.mask is None:
        mask = np.ones(data.shape[:3]).astype(np.bool)
    else:
        mask = nib.load(args.mask).get_fdata().astype(np.bool)

    bvals = np.genfromtxt(args.bvals)
    b0s = bvals<100 # b0 mask

    outpath = args.out

    # Casting data as float
    data = data.astype(np.float)
    print('Data shape is {}'.format(data.shape))
    print('Mask shape is {}'.format(mask.shape))

    # Check mask dimensions
    if data.shape[:3] != mask.shape:
        print('Data and mask dimensions do not match, terminating')
        return 0

    data_mean = (data[mask,:].mean(axis = 0))  # Calculate the mean time sigal within the mask 
    data_mean /= data_mean[b0s].mean() # normalize with mean b0 intensity

    n_vols = data.shape[3]
    vols = np.linspace(0, n_vols-1, n_vols, dtype = np.int)

    vols_nob0 = vols[np.logical_not(b0s)]

    # Plot timeseries
    fig, axs = plt.subplots(2)
    fig.suptitle('Mean Signal Across Time')
    axs[0].plot(vols, data_mean, label = 'Full signal')
    axs[0].grid('minor')
    axs[0].set_title('Full signal')
    axs[0].set_xlabel('Volume')
    axs[0].set_ylabel('Signal')

    axs[1].plot(vols_nob0, data_mean[np.logical_not(b0s)], label = 'Signal without b0 volumes')    
    axs[1].grid('minor')
    axs[1].set_title('Signal Excluding b0 Volumes')
    axs[1].set_xlabel('Volume')
    axs[1].set_ylabel('Signal')
    
    plt.show()

    # Save output to specified folder
    np.savetxt(outpath + '/meanvols.txt', np.concatenate((vols[:, None], data_mean[:, None]), axis = 1), fmt = '%d, %2.5f')

if __name__ == '__main__':
    main()

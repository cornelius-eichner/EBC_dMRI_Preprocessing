#!/usr/bin/env python3
# -*- coding: utf-8 -*-

from __future__ import division, print_function

import argparse

from time import time

# import pylab as pl
import nibabel as nib
import numpy as np

import skfuzzy as fuzz


DESCRIPTION = """
Compute fuzzy segmentation from an arbitrary amount of images.
"""

EPILOG = """
Michael Paquette, MPI CBS, 2021.
"""


class CustomFormatter(argparse.ArgumentDefaultsHelpFormatter, argparse.RawTextHelpFormatter):
    pass


def buildArgsParser():

    p = argparse.ArgumentParser(description=DESCRIPTION,
                                epilog=EPILOG,
                                formatter_class=CustomFormatter)

    p.add_argument('--data', type=str, nargs='+', default=[],
                   help='Path of the input data (one or more).')

    p.add_argument('--mask', type=str, nargs='*', default=[],
                   help='Path of the input mask (one or more).')

    p.add_argument('--out', type=str,
                   help='Path and basename for the outputs.')

    p.add_argument('--n', type=int, default=3,
                   help='Number of classes for the segmentation')


    return p



def main():
    parser = buildArgsParser()
    args = parser.parse_args()


    if args.out is None:
        print('Need output name')
        return None



    # load and concatenate all the data
    print('Loading data')
    data_img = [nib.load(fname) for fname in args.data]
    affine = data_img[0].affine
    data_data = []
    for img in data_img:
        tmp = img.get_fdata()
        print('data shape = {:}'.format(tmp.shape))
        # need 4D data for the concatenate
        if tmp.ndim == 3:
            tmp = tmp[..., None]
        data_data.append(tmp)
    data = np.concatenate(data_data, axis=3)
    print('Full data shape = {:}'.format(data.shape))
    del data_data



    # load and multiply all the mask
    print('Loading Mask')
    mask = np.ones(data.shape[:3], dtype=np.bool)
    mask_data = [nib.load(fname).get_fdata().astype(np.bool) for fname in args.mask]
    for tmp in mask_data:
        mask = np.logical_and(mask, tmp)
    print('Final mask has {:} voxels ({:.1f} % of total)'.format(mask.sum(), 100*mask.sum()/np.prod(data.shape[:3])))
    del mask_data


    print('Clipping all data [0, inf)')
    data = np.clip(data, 0, np.inf)
    data[np.isnan(data)] = 0
    data[np.isinf(data)] = 0


    print('Vectorize data')
    data_vector = data[mask]


    XX, YY, ZZ = np.meshgrid(range(data.shape[0]), range(data.shape[1]), range(data.shape[2]), indexing='ij')
    coord_grid = np.concatenate((XX[...,None], YY[...,None], ZZ[...,None]), axis=3)
    linear_coords = coord_grid[mask]



    print('Normalize data to mean=0 and std=1')
    means = np.mean(data_vector, axis=0)
    stds = np.std(data_vector, axis=0)
    data_standard = (data_vector - means[None,:]) / stds[None,:]


    ncenters = args.n
    print('Run fuzzy clustering with {:} class'.format(ncenters))
    start_time = time()
    cntr, u, u0, d, jm, p, fpc = fuzz.cluster.cmeans(
        data_standard.T, ncenters, 2, error=0.005, maxiter=1000, init=None)
    end_time = time()
    print('Elapsed time = {:.2f} s'.format(end_time - start_time))


    for j in range(ncenters):
        tmp = np.zeros(mask.shape[:3], dtype=np.float)
        tmp[(tuple(linear_coords[:,0]), tuple(linear_coords[:,1]), tuple(linear_coords[:,2]))] = u[j]
        nib.Nifti1Image(tmp, affine).to_filename(args.out + 'fuzzy_label_{}class_idx_{}.nii.gz'.format(ncenters, j))



if __name__ == "__main__":
    main()




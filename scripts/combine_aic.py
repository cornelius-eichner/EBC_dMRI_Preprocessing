#!/usr/bin/env python3
# -*- coding: utf-8 -*-

from __future__ import division, print_function

import argparse

from time import time

# import pylab as pl
import nibabel as nib
import numpy as np




DESCRIPTION = """
Pick the best odf ratio for each voxel based on AIC.
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

    p.add_argument('--iaic', type=str, nargs='+', default=[],
                             help='Path of the input AICs.')

    p.add_argument('--iodf', type=str, nargs='+', default=[],
                             help='Path of the input ODFs.')

    p.add_argument('--mask', type=str, nargs='*', default=[],
                             help='Path of the input mask (one or more).')

    p.add_argument('--ratios', type=float, nargs='+', default=[],
                             help='Path of the ratios.')  

    p.add_argument('--oodf', type=str,
                             help='Path of the output best ODFs.')

    p.add_argument('--oaic', type=str,
                             help='Path of the output best AICs.')

    p.add_argument('--oratio', type=str,
                             help='Path of the output best ratios.')

    return p



def main():
    parser = buildArgsParser()
    args = parser.parse_args()


    # Debug argparse
    # print('Input AIC')
    # for fname in args.iaic:
    #   print(fname)
    # print('Input ODF')
    # for fname in args.iodf:
    #   print(fname)
    # print('Input Mask')
    # for fname in args.mask:
    #   print(fname)
    # print('Input Ratios')
    # for fname in args.ratios:
    #   print(fname)

    # print('Outputs')
    # print(args.oodf)
    # print(args.oaic)
    # print(args.oratio)






    if (args.oodf is None) or (args.oaic is None) or (args.oratio is None):
        print('Need output name(s)')
        return None



    # load and concatenate all the data
    print('Loading AIC data')
    data_img = [nib.load(fname) for fname in args.iaic]
    affine = data_img[0].affine
    data_data = []
    for img in data_img:
        tmp = img.get_fdata()
        # print('data shape = {:}'.format(tmp.shape))
        # need 4D data for the concatenate
        if tmp.ndim == 3:
            tmp = tmp[..., None]
        data_data.append(tmp)
    data_aics = np.concatenate(data_data, axis=3)
    print('Full data shape = {:}'.format(data_aics.shape))
    del data_data


    # load and concatenate all the data
    print('Loading ODF data')
    data_img = [nib.load(fname) for fname in args.iodf]
    # affine = data_img[0].affine
    data_data = []
    for img in data_img:
        tmp = img.get_fdata()
        # print('data shape = {:}'.format(tmp.shape))
        # need 5D data for the concatenate
        if tmp.ndim == 4:
            tmp = tmp[..., None]
        data_data.append(tmp)
    data_odfs = np.concatenate(data_data, axis=4)
    print('Full data shape = {:}'.format(data_odfs.shape))
    del data_data



    # load and multiply all the mask
    print('Loading Mask')
    mask = np.ones(data_aics.shape[:3], dtype=np.bool)
    mask_data = [nib.load(fname).get_fdata().astype(np.bool) for fname in args.mask]
    for tmp in mask_data:
        mask = np.logical_and(mask, tmp)
    print('Final mask has {:} voxels ({:.1f} % of total)'.format(mask.sum(), 100*mask.sum()/np.prod(data_aics.shape[:3])))
    del mask_data

    
    ratios = np.array(args.ratios)


    # find best aic
    print('Find voxelwise best AIC')
    best_idx = np.argmin(data_aics, axis=3)


    best_aic = np.zeros(mask.shape)
    best_ratio = np.zeros(mask.shape)
    best_odf = np.zeros(mask.shape+(data_odfs.shape[3],))
    # repack everything
    for xyz in np.ndindex(mask.shape):
        best_aic[xyz] = data_aics[xyz][best_idx[xyz]]
        best_ratio[xyz] = ratios[best_idx[xyz]]
        best_odf[xyz] = data_odfs[xyz][:, best_idx[xyz]]


    nib.Nifti1Image(best_aic, affine).to_filename(args.oaic)
    nib.Nifti1Image(best_ratio, affine).to_filename(args.oratio)
    nib.Nifti1Image(best_odf, affine).to_filename(args.oodf)



if __name__ == "__main__":
    # import sys
    # print(sys.argv[1:])    
    main()

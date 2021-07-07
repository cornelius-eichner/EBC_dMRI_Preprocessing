#!/usr/bin/env python3
# -*- coding: utf-8 -*-

from __future__ import division, print_function

import argparse

from time import time

# import pylab as pl
import nibabel as nib
import numpy as np


DESCRIPTION = """
Compute average from an arbitrary amount of images.
"""


class CustomFormatter(argparse.ArgumentDefaultsHelpFormatter, argparse.RawTextHelpFormatter):
    pass


def buildArgsParser():

    p = argparse.ArgumentParser(description=DESCRIPTION,
                                formatter_class=CustomFormatter)

    p.add_argument('--data', type=str, nargs='+', default=[],
                   help='Path of the input data (two or more).')

    p.add_argument('--out', type=str,
                   help='Output Path')


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


    print('Clipping all data [0, inf)')
    data = np.clip(data, 0, np.inf)
    data[np.isnan(data)] = 0
    data[np.isinf(data)] = 0

    # Saving average maps
    if len(data.shape) == 4:
        print('Saving Average Maps')
        nib.Nifti1Image(np.median(data, axis = 3), affine).to_filename(args.out)
    if len(data.shape) != 4:
        print('Dimension mismatch, skipping')


if __name__ == "__main__":
    main()




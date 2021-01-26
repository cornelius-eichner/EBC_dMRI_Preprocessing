#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import argparse
import nibabel as nib
import numpy as np
import os
import pylab as plt


DESCRIPTION =   'Fit Rayleigh Distribution to noisemap data. Cornelius Eichner 2020'

np.set_printoptions(precision=2)

def rayleigh_dist(x, sigma):
    f = (x / sigma**2) * np.exp(- x**2 / (2 * sigma**2) )

    zero_mask = np.ones_like(x)
    zero_mask[x<=0] = 0

    f *= zero_mask

    return f


def buildArgsParser():
    p = argparse.ArgumentParser(description=DESCRIPTION)
    p.add_argument('--in', dest='input', action='store', type=str,
                            help='Name of the input nii file')

    p.add_argument('--out', dest='output', action='store', type=str,
                            help='Name of the output folder')

    p.add_argument('--axes', dest='axes', action='store', type=str,
                            help='Calculate Sigma along which axes (e.g., 0,2)')

    return p


def main():
    # Load parser to read data from command line input
    parser = buildArgsParser()
    args = parser.parse_args()

    # Load input variables
    PATH_IN     = os.path.realpath(args.input)
    PATH_OUT    = os.path.realpath(args.output)
    AXES        = eval(args.axes) 

    # Load input file
    print('Loading Input Data {}'.format(PATH_IN))
    data = nib.load(PATH_IN).get_fdata().astype(np.float)
    dims = data.shape
    
    mean_along_axes = data.mean(axis = AXES)

    # We assume a Rician distribution and convert the mean signal to sigma using the following relation 
    sigma_along_axes = mean_along_axes / np.sqrt(np.pi / 2)

    # Plot the noisemap and the sigma variation along the specifiec axes
    plt.figure()
    plt.subplot(221)
    plt.title('Saggital View')
    plt.imshow(data[round(dims[0]/2), :, :])
    
    plt.subplot(222)
    plt.title('Coronal View')
    plt.imshow(data[:, round(dims[1]/2), :])
    
    plt.subplot(223)
    plt.title('Axial View')
    plt.imshow(data[:, :, round(dims[2]/2)])

    plt.subplot(224)
    plt.title('Sigma Variation Along the Specifiec Axes')
    plt.plot(sigma_along_axes)

    plt.show()

    # Save sigma variation along specified axis
    np.savetxt(PATH_OUT, sigma_along_axes, fmt='%.18e', delimiter=',')


if __name__ == '__main__':
    main()

#!/usr/bin/env python
# -*- coding: utf-8 -*-

from __future__ import division, print_function

import argparse

from time import time

# import pylab as pl
import nibabel as nib
import numpy as np

from dipy.data import get_sphere
from dipy.reconst.shm import real_sh_tournier, real_sh_descoteaux, order_from_ncoef

from odf_utils import peak_directions_sh_vol


def _build_args_parser():
    p = argparse.ArgumentParser(
        description=__doc__, formatter_class=argparse.RawTextHelpFormatter)
    p.add_argument('input', metavar='input',
                   help='Path of the input odf SH volume.')
    p.add_argument('outputnufo', metavar='outputnufo',
                   help='Path of the output nufo volume.')
    p.add_argument('outputdir', metavar='outputdir',
                   help='Path of the output normalized peaks orientation.')
    p.add_argument('outputlen', metavar='outputlen',
                   help='Path of the output absolute peak lenght.')
    p.add_argument('--relth', dest='relth', metavar='relth', type=float, default=0.25,
                    help='Relative threshold for peak extraction.')
    p.add_argument('--minsep', dest='minsep', metavar='minsep', type=float, default=15,
                    help='Minimum separation angle in degree for peak extraction.')
    p.add_argument('--maxn', dest='maxn', metavar='maxn', type=int, default=10,
                    help='Maximum number of peak extracted per ODF.')
    p.add_argument(
        '--mask', dest='mask', metavar='mask',
        help='Path to a binary mask.\nOnly data inside the mask will be used '
             'for computations and reconstruction. (Default: None)')
    return p


def main():
    parser = _build_args_parser()
    args = parser.parse_args()

    odf_fname = args.input
    nufo_fname = args.outputnufo
    dir_fname = args.outputdir
    len_fname = args.outputlen

    N_peaks = args.maxn
    sh_basis = 'tournier07'
    sphere_name = 'repulsion724'
    relative_peak_threshold = args.relth
    min_separation_angle = args.minsep


    print('max N_peaks = {}'.format(N_peaks))
    print('relative_peak_threshold = {}'.format(relative_peak_threshold))
    print('min_separation_angle = {} deg'.format(min_separation_angle))

    if sh_basis == 'tournier07':
        sh_func = real_sh_tournier
    elif sh_basis == 'descoteaux07':
        sh_func = real_sh_descoteaux
    else:
        print('Unknown sh basis!') # could be a real logged warning/error
        return None



    odf_img = nib.load(odf_fname)
    odf_sh = odf_img.get_fdata()
    affine = odf_img.affine

    if args.mask is None:
        mask = np.ones(odf_sh.shape[:3]).astype(np.bool)
    else:
        mask = nib.load(args.mask).get_fdata().astype(np.bool)



    lmax = int(order_from_ncoef(odf_sh.shape[-1], full_basis=False))
    sphere = get_sphere(sphere_name)
    B, m, n = sh_func(lmax, sphere.theta, sphere.phi)



    start_time = time()
    peak_dir, peak_val, peak_ind = peak_directions_sh_vol(odf_sh, B, sphere, relative_peak_threshold=relative_peak_threshold, min_separation_angle=min_separation_angle, Npeaks=N_peaks, mask=mask)
    end_time = time()
    print('Elapsed time = {:.2f} s'.format(end_time - start_time))



    nufo = (peak_val>0).sum(axis=3)
    peak_orientation = peak_dir
    peak_lenght = peak_val

    nib.Nifti1Image(nufo, affine).to_filename(nufo_fname)
    nib.Nifti1Image(peak_orientation, affine).to_filename(dir_fname)
    nib.Nifti1Image(peak_lenght, affine).to_filename(len_fname)




if __name__ == "__main__":
    main()



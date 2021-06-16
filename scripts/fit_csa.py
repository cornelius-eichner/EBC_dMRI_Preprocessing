#!/usr/bin/env python3
# -*- coding: utf-8 -*-

from __future__ import division, print_function

import numpy as np
import nibabel as nib
from time import time

from dipy.data import get_sphere
from dipy.core.gradients import gradient_table
from dipy.io.gradients import read_bvals_bvecs
from dipy.reconst.shm import CsaOdfModel

from exvivo_odf_sharpening.shconv import convert_sh_basis


def main(dwipath, bvalpath, bvecpath, outputpath, NCORE=1, tau=1e-5, lambda_=0.006, shmax=6):

	NCORE = int(NCORE)
	tau = float(tau)
	lambda_ = float(lambda_)
	shmax = int(shmax)

	# load bvals and bvecs
	print('Load bvec/bvec')
	bvals, bvecs = read_bvals_bvecs(bvalpath,bvecpath)
	# fix flips
	print('bvec: Flip X')
	bvecs[:, 0] *= -1


	# check bvecs norms
	# print(np.linalg.norm(bvecs, axis=1))



	print('Assumes properly rounded single shell bvals')
	print('Min bval = {:} (should be zero)'.format(bvals.min()))
	print('bval shells = {:}'.format(set(bvals)))
	# # truncated bvals to sphere
	# bvals[bvals < 100] = 0
	# bvals[bvals > 4000] = 5000



	# sphere for conversion for sh conversion to tournier format
	# using repulsion100 because we expect sh_order 8 or less
	sphere_conv = get_sphere('repulsion100')

	gtab = gradient_table(bvals, bvecs)

	data_img = nib.load(dwipath)
	data = data_img.get_fdata()
	affine = data_img.affine
	print('This script expect normalized dwi data')
	print('This script assumes the first volume is a brain mask')
	mask = data[..., 0].astype(np.bool)


	# CSA model
	# fitting stuff
	print('Using shmax = {:}'.format(shmax))
	print('Using tau = {:}'.format(tau))
	print('Using lambda = {:}'.format(lambda_))

	print('Starting fitting')
	csa_model = CsaOdfModel(gtab, sh_order=shmax, min_signal=tau, smooth=lambda_, assume_normed=False)
	start_time = time()
	csa_fit = csa_model.fit(data, mask=mask)
	end_time = time()
	print('Elapsed time = {:.2f} s'.format(end_time - start_time))

	start_time = time()
	tournier_sh = convert_sh_basis(csa_fit.shm_coeff, sphere_conv, input_basis='descoteaux07', nbr_processes=NCORE)
	nib.Nifti1Image(tournier_sh, affine).to_filename(outputpath)
	end_time = time()
	print('Elapsed time (conversion({} cores)) = {:.2f} s'.format(NCORE, end_time - start_time))




if __name__ == "__main__":
    import sys
    print('args:')
    # dwipath is path to normalized DWI with first volume as a brain mask
    # bvalpath is path to rounded bvals
    # bvecpath is path to normalized bvecs
    # outputpath is path to save tournier format SH
    # NCORE is the nuber of core used ONLY FOR THE CONVERSION TO TOURNIER SH
    # tau is the minimal signal cutoff
    # lambda_ is the laplace-beltrami normalization weight
    # shmax is the spherical harmonic maximum order
    print('dwipath, bvalpath, bvecpath, outputpath, NCORE=1, tau=1e-5, lambda_=0.006, shmax=6')
    main(*sys.argv[1:])

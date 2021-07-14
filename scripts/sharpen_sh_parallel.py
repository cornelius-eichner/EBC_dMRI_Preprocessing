#!/usr/bin/env python3

import argparse
import numpy as np
import nibabel as nib
from time import time

from dipy.data import get_sphere
from dipy.reconst.csdeconv import odf_sh_to_sharp
from dipy.reconst.shm import calculate_max_order

from shconv import convert_sh_basis
from _sharpen_parallel import odf_sh_to_sharp_parallel


DESCRIPTION =   """
Sharpen ODFs using Descoteaux Sharpening"""

np.set_printoptions(precision=2)

def buildArgsParser():
    p = argparse.ArgumentParser(description=DESCRIPTION)
    p.add_argument('--in', dest='sh_fname', action='store', type=str,
                            help='Name of the input nii file')

    p.add_argument('--out', dest='sh_sharp_fname', action='store', type=str,
                            help='Name of the sharpened output nii file')

    p.add_argument('--mask', dest='mask', action='store', type=str,
                            help='Optional: Name of mask nii file')

    p.add_argument('--ratio', dest='ratio', action='store', type=float, default = 2., 
                            help='ratio of ODF sharpening')
    
    p.add_argument('--tau', dest='tau', action='store', type=float, default = 0.1, 
                            help='Sharpening with tau')
    
    p.add_argument('--lambda', dest='lambda_', action='store', type=float, default = 1., 
                            help='Sharpening with lambda')
    
    p.add_argument('--csa_norm', dest='csa_norm', action='store', type=bool, default=True, 
                                help='Sharpening with r2_terms (True/False)')

    p.add_argument('--cores', dest='cores', action='store', type=int, default=1, 
                            help='Name of the shifted output file')

    return p


def main():

    parser = buildArgsParser()
    args = parser.parse_args()

    NCORE = args.cores

    sh_img = nib.load(args.sh_fname)
    sh = sh_img.get_fdata()
    affine = sh_img.affine

    if args.mask is None:
        mask = np.ones(sh.shape[:3], dtype=np.bool)
    else:
        mask = nib.load(args.mask).get_fdata().astype(np.bool)

    lmax = calculate_max_order(sh.shape[3], False)

    # sphere_conv = get_sphere('repulsion100')
    # descoteaux_sh = convert_sh_basis(sh, sphere_conv, input_basis='tournier07', nbr_processes=NCORE)
    reg_sphere = get_sphere('symmetric362')


    # sharpend CSD model
    ratio_csd_sharp = args.ratio

    tau_csd_sharp = args.tau # default = 0.1
    lambda_csd_sharp = args.lambda_ # default = 1
    sh_order_sharp = lmax
    solid_angle_norm = args.csa_norm # default True
    # solid_angle_norm = False # qball

    print('Sharpening with ratio = {:}'.format(ratio_csd_sharp))
    print('Sharpening with tau = {:}'.format(tau_csd_sharp))
    print('Sharpening with lambda_ = {:}'.format(lambda_csd_sharp))
    print('Sharpening with lmax = {:}'.format(sh_order_sharp))
    print('Sharpening with r2_term = {:}'.format(solid_angle_norm))

    start_time = time()
    sh_csd_sharp = odf_sh_to_sharp_parallel(sh, reg_sphere, mask=mask, basis='tournier07', ratio=1/ratio_csd_sharp, sh_order=sh_order_sharp, lambda_=lambda_csd_sharp, tau=tau_csd_sharp, r2_term=solid_angle_norm, maxprocess=NCORE)
    end_time = time()
    print('Elapsed time = {:.2f} s'.format(end_time - start_time))



    # start_time = time()
    # tournier_sh_enh = convert_sh_basis(sh_coef_enh, sphere_conv, input_basis='descoteaux07', nbr_processes=NCORE)
    nib.Nifti1Image(sh_csd_sharp, affine).to_filename(args.sh_sharp_fname)
    # end_time = time()
    # print('Conversion to MRTRIX sh ({} cores) = {:.2f} s'.format(NCORE, end_time - start_time))


if __name__ == "__main__":
    main()



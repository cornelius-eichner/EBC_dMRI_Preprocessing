#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import argparse
from dipy.core.gradients import gradient_table
from dipy.io.gradients import read_bvals_bvecs
import dipy.reconst.dti as dti
import nibabel as nib
import numpy as np
import pylab as pl
# from scilpy.utils.bvec_bval_tools import (normalize_bvecs, is_normalized_bvecs)


desciption = """
Global intensity correction for temperature difference.
1) Fit DTI on temperature-stable volume subset
2) Estimate temperature of each volume from disparity with stabe subset fit
2a) TODO: smooth or model the temperature as function of time
3) Scale each volume for the main mean diffusivity (estimated as 1/bval)
"""


def _build_args_parser():
    p = argparse.ArgumentParser(description=desciption, formatter_class=argparse.RawTextHelpFormatter)

    p.add_argument('data', metavar='data', help='Path of the dwi nifti file.')
    p.add_argument('bval', metavar='bval', help='Path of the bval file.')
    p.add_argument('bvec', metavar='bvec', help='Path of the bvec file.')
    p.add_argument('output', metavar='output', help='Path of the output nifti.')
    p.add_argument('outputks', metavar='output', help='Path of the diffusivity multiplier map.')
    
    # requires either a file with volume mask or a number of last volume
    group = p.add_mutually_exclusive_group(required=True)
    group.add_argument('--index', metavar='index', help='Path to files with 1s in the position of volume to include')
    group.add_argument('--last', metavar='last', type=int, help='Number of non-b0 volume to include starting from the end.')

    p.add_argument('--mask', metavar='mask', help='Path of the brain mask for normalization.')

    return p


def main():
    parser = _build_args_parser()
    args = parser.parse_args()

    print('LOADING DATA')
    # load data
    img = nib.load(args.data)
    data = img.get_fdata()

    # load bval bvec
    bval, bvec = read_bvals_bvecs(args.bval, args.bvec)
    gtab = gradient_table(bval, bvec)
    # detect b0
    b0_th = 75.
    b0_index = np.where(bval < b0_th)[0]

    # build include index
    if args.index is None:
        index = np.zeros(bval.shape[0], dtype=np.bool)
        # include the last args.last non-b0
        N = args.last
        # list of non-zero index
        tmp = np.arange(bval.shape[0])[bval >= b0_th]
        index[tmp[-N:]] = True
        # include all b0s
        index[b0_index] = True
    else:
        index = np.genfromtxt(args.index).astype(np.bool)

    if index.shape[0] != bval.shape[0]:
        print('index length different from bval length')
        return None 

    if args.mask is None:
        mask = np.ones(data.shape[:3], dtype=np.bool)
    else:
        mask = nib.load(args.mask).get_fdata().astype(np.bool)

    totalVoxel = np.prod(mask.shape)
    voxelInMask = mask.sum()
    print('{} voxels out of {} inside mask ({:.1f}%)'.format(voxelInMask, totalVoxel, 100*voxelInMask/totalVoxel))



    print('COMPUTING TIME CURVES')
    # compute per-volume mean inside mask
    volume_mean_intensity = data[mask].mean(axis=0)

    viz_hack = volume_mean_intensity.copy()
    viz_hack[b0_index] = np.nan

    pl.figure()
    pl.plot(volume_mean_intensity, color='black', label='mean intensity in mask')
    pl.scatter(np.where(index), np.ones(index.sum())*(0.95*volume_mean_intensity.min()), label='Included', color='red')
    pl.title('Mean intensity in mask (WITH b0)')
    pl.legend()

    pl.figure()
    pl.plot(viz_hack, color='black', label='mean intensity in mask')
    pl.scatter(np.where(index), np.ones(index.sum())*(0.95*volume_mean_intensity.min()), label='Included', color='red')
    pl.title('Mean intensity in mask (WITHOUT b0)')
    pl.legend()

    pl.show()





    # fit DTI on included volume in index
    low_bvec = bvec[index]
    low_bval = bval[index]

    data_low = data[..., index]


    gtab_low = gradient_table(low_bval, low_bvec)
    tenmodel_low = dti.TensorModel(gtab_low)


    print('FITTING DTI')
    tenmodel_low = dti.TensorModel(gtab_low, fit_method='WLS', return_S0_hat=True)

    # Dipy has hard min signal cutoff of 1e-4, so we amplify
    # set the non-zero minimum to the threshold
    data_low_masked = data_low[mask]
    # this is gettho more and more garbage, to accomodate debias negative data
    # we look at the min above zero
    # in pratice this is terrible and we should just scale the data before
    multiplier = 1e-4 /  data_low_masked[(data_low_masked>0)].min()
    

    # Change required in dipy in dti.py  S0_params[mask] = model_S0
    # S0_params[mask] = model_S0.squeeze()
    tenfit_low = tenmodel_low.fit(multiplier*data_low, mask=mask)


    print('PREDICTING SIGNALS')
    # predict signal for each volume for fit
    predicted_S0 = tenfit_low.S0_hat

    predicted_signal = tenfit_low.predict(gtab)

    predicted_normalized_signal = predicted_signal / predicted_S0[..., None]
    predicted_normalized_signal[np.isnan(predicted_normalized_signal)] = 0
    predicted_normalized_signal[np.isinf(predicted_normalized_signal)] = 0

    predicted_adc = -np.log(predicted_normalized_signal)/bval[None, None, None, :]
    predicted_adc[np.isinf(predicted_adc)] = 0
    predicted_adc[np.isnan(predicted_adc)] = 0


    print('COMPUTING TEMPERATURE')
    ks = 1 - (np.log(multiplier*data/(predicted_signal)) * (bval[None, None, None, :]*predicted_adc)**-1)

    ks[np.isnan(ks)] = 1
    ks[np.isinf(ks)] = 1

    # save the diffusivity multiplier map
    nib.nifti1.Nifti1Image(ks, img.affine).to_filename(args.outputks)


    mean_directional_k = np.median(ks[mask], axis=(0,))

    pl.figure()
    pl.plot(mean_directional_k )
    pl.axhline(1, color='red', linestyle='dashed')
    pl.title('Estimated (median) diffusivity multiplier in mask per volume')
    pl.show()



    print('COMPUTING CORRECTION')
    # diffusivity to center the calibration
    D_calibrate = 1/bval.max()
    print('Calibrating for diffusivity 1/bmax = 1/{:.0f} = {:.2e}'.format(bval.max(), D_calibrate))
    heat_calibrate = np.exp(-bval*mean_directional_k*D_calibrate)

    # pl.plot(np.exp(-bval*D_calibrate)/heat_calibrate)
    meank_fix_correction = np.exp(-bval*D_calibrate)/heat_calibrate

    data_meank_fix = data * meank_fix_correction[None,None,None,:]
    meandata_meank_fix = data_meank_fix[mask].mean(axis=(0,))


    viz_hack2 = meandata_meank_fix.copy()
    viz_hack2[b0_index] = np.nan

    pl.figure()
    pl.plot(volume_mean_intensity, color='black', label='no correction')
    pl.plot(meandata_meank_fix, color='red', label='with correction')
    # pl.scatter(np.where(index), np.ones(index.sum())*(0.95*volume_mean_intensity.min()), label='Included', color='red')
    pl.title('Mean intensity in mask (WITH b0)')
    pl.legend()

    pl.figure()
    pl.plot(viz_hack, color='black', label='no correction')
    pl.plot(viz_hack2, color='red', label='with correction')
    # pl.scatter(np.where(index), np.ones(index.sum())*(0.95*volume_mean_intensity.min()), label='Included', color='red')
    pl.title('Mean intensity in mask (WITHOUT b0)')
    pl.legend()

    pl.show()



    print('SAVING CORRECTED NIFTI')
    nib.nifti1.Nifti1Image(data_meank_fix, img.affine).to_filename(args.output)




if __name__ == "__main__":
    main()

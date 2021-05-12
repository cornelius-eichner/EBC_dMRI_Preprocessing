#!/usr/bin/env python3
# -*- coding: utf-8 -*-

from __future__ import division, print_function

# import argparse

from time import time

# import pylab as pl
import nibabel as nib
import numpy as np

from skimage.morphology import erosion, closing
# from sklearn.cluster import MiniBatchKMeans
import skfuzzy as fuzz



def main(maskpath, fapath, mdpath, b0path, flash1path, flash2path, flash3path, flash4path, flash5path, maskpath_out, clusterbase, nclass):

    # load data
    print('Load data')
    mask_img = nib.load(maskpath)
    mask = mask_img.get_fdata().astype(np.bool)
    affine = mask_img.affine


    dataname = [fapath, mdpath, b0path, flash1path, flash2path, flash3path, flash4path, flash5path]


    data_clip_range = [(0, 1),
                       (0, 3e-3),
                       (0, np.inf),
                       (0, np.inf),
                       (0, np.inf),
                       (0, np.inf),
                       (0, np.inf),
                       (0, np.inf)]

    
    data_raw = []
    for fname in dataname:
        tmp = nib.load(fname).get_fdata()
        tmp[np.isnan(tmp)] = 0
        tmp[np.isinf(tmp)] = 0
        data_raw.append(tmp)




    # # erode mask
    # print('Apply Closing to mask')
    # selem = np.ones((3,3,3))
    # mask_eroded = closing(np.pad(mask, selem.shape[0]), selem)
    # N_pass = 2
    # print('Apply {:} pass of erosion to mask'.format(N_pass))
    # for i in range(N_pass):
    #     mask_eroded = erosion(mask_eroded, selem)
    # mask_eroded = mask_eroded[selem.shape[0]:-selem.shape[0], selem.shape[0]:-selem.shape[0], selem.shape[0]:-selem.shape[0]]
    # nib.Nifti1Image(mask_eroded.astype(np.int8), affine).to_filename(maskpath_out)
    mask_eroded = mask



    # make data vector
    print('Vectorize and join data in mask')
    data_vector = np.zeros((mask_eroded.sum(), 3+len(dataname))) # 3 spatial + N maps
    i = 0
    for idx in np.ndindex(mask_eroded.shape):
        if mask_eroded[idx]:
            tmp = [idx[0], idx[1], idx[2]]
            for datadim in range(len(dataname)):
                tmp.append(data_raw[datadim][idx])
            data_vector[i] = tmp
            i += 1



    # clip data
    print('Clip data')
    data_vector_clipped = np.empty(data_vector.shape)
    # data_vector_clipped = data_vector.copy()
    for i in range(len(data_raw)):
        data_vector_clipped[:,i+3] = np.clip(data_vector[:, i+3], data_clip_range[i][0], data_clip_range[i][1])


    # # data normalization attempt 1
    # # max-normalize at 99% percentile (this assumes all data are clipped to 0)
    # percentile = 0.99
    # data_percentile = []
    # data_maxnorm = np.empty(data_vector.shape)
    # data_maxnorm[:,:3] = data_vector[:,:3].copy()
    # for i in range(len(data_raw)):
    #     data_percentile.append(np.quantile(data_vector_clipped[:,i+3], percentile))
    #     data_maxnorm[:,i+3] = data_vector_clipped[:,i+3] / data_percentile[i]


    # data normalization attempt 2
    # zero mean and std one
    print('Normalize data to mean=0 and std=1')
    data_means = []
    data_stds = []
    data_standard = np.empty(data_vector.shape)
    # data_standard = data_vector.copy()
    for i in range(len(data_raw)):
        data_means.append(data_vector_clipped[:,i+3].mean())
        data_stds.append(data_vector_clipped[:,i+3].std())
        data_standard[:,i+3] = (data_vector_clipped[:,i+3] - data_means[i]) / data_stds[i]



    ncenters = int(nclass)
    print('Run fuzzy clustering with {:} class'.format(ncenters))
    start_time = time()
    cntr, u, u0, d, jm, p, fpc = fuzz.cluster.cmeans(
        data_standard[:,3:].T, ncenters, 2, error=0.005, maxiter=1000, init=None)
    end_time = time()
    print('Elapsed time = {:.2f} s'.format(end_time - start_time))


    for j in range(ncenters):
        tmp = np.zeros(mask.shape[:3], dtype=np.float)
        tmp[(tuple(data_vector[:, 0].astype(np.int)), tuple(data_vector[:, 1].astype(np.int)), tuple(data_vector[:, 2].astype(np.int)))] = u[j]
        nib.Nifti1Image(tmp, affine).to_filename(clusterbase + 'fuzzy_label_{}class_idx_{}.nii.gz'.format(ncenters, j))



if __name__ == "__main__":
    import sys
    main(*sys.argv[1:])




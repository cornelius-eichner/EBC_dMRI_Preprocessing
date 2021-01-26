#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import argparse
import numpy as np
import nibabel as nib
import pylab as pl


DESCRIPTION = """
Ultra lightweight 3D data viewer with
- Orthoview
- Slice Mosaic
- Intensity Histogram
"""

def buildArgsParser():
    p = argparse.ArgumentParser(description=DESCRIPTION)
    p.add_argument('input', action='store', type=str,
                            help='Path of the volume (nifti format)')

    p.add_argument('--mask', metavar='',
                             help='Path to a binary mask (nifti format)')

    p.add_argument('--ax', dest='mosaic_axis', type=int, default='0',
                           help='Data axis for mosaic plot.')

    p.add_argument('--mos', dest='mosaic', action='store_true',
                            help='Flag to plot the Slice Mosaic')

    p.add_argument('--ort', dest='ortho', action='store_true',
                            help='Flag to plot the Orthoview')

    p.add_argument('--his', dest='hist', action='store_true',
                            help='Flag to plot the Intensity Histogram')

    p.add_argument('--min', dest='hist_min', type=float,
                           help='Minimum threshold for histogram')

    p.add_argument('--max', dest='hist_max', type=float,
                           help='Maximum threshold for histogram')

    p.add_argument('--all', dest='plot_all', action='store_true',
                            help='Flag to plot all features')

    p.add_argument('--4d', dest='index_4d', type=int, default='0',
                           help='Index for 4th dimension.')

    p.add_argument('--loghis', dest='loghist', action='store_true',
                            help='Plot histogram with log axis')

    return p



def main():
    parser = buildArgsParser()
    args = parser.parse_args()

    # Plotting flags
    plot_mosaic = False
    plot_histogram = False
    plot_orthoview = False
    if args.plot_all:
        plot_mosaic = True
        plot_orthoview = True
        plot_histogram = True
    if args.mosaic:
        plot_mosaic = True
    if args.ortho:
        plot_orthoview = True
    if args.hist:
        plot_histogram = True
    if args.loghist:   
        plot_histogram_log = True
    i4 = args.index_4d

    # enforcing 3D data
    datapath = args.input
    data = nib.load(datapath).get_data()
    if data.ndim < 3:
        print('Data is less than 3D, terminating')
        return 0
    if data.ndim == 4:
        print('Data is 4D, taking data[:,:,:,{}]'.format(i4))
        data = data[...,i4]
    if data.ndim == 5:
        print('Data is 5D, taking data[:,:,:,{},0]'.format(i4))
        data = data[...,i4,0]
    if data.ndim > 5:
        print('Data is more than 5D, terminating')
        return 0

    X,Y,Z = data.shape
    # Casting data as float
    data = data.astype(np.float)
    print('Data shape is {}'.format(data.shape))

    if args.mask is None:
        mask = np.ones_like(data).astype(np.bool)
    else:
        mask = nib.load(args.mask).get_data().astype(np.bool)

    # masking data
    data = data*mask


    # Mosaic
    if plot_mosaic:
        mosaic_axis = args.mosaic_axis
        if mosaic_axis not in [0,1,2]:
            print('Invalid mosaic axis, terminating')
            return 0
        else:
            print('Plotting mosaic along axis {}'.format(mosaic_axis))


        N = data.shape[mosaic_axis]
        subN = int(np.ceil(np.sqrt(N)))
        pl.figure()

        if mosaic_axis == 0:
            tmp = np.zeros((subN*Z, subN*Y))
            for i in range(N):
                pos1, pos2 = divmod(i, subN)
                tmp[pos2*Z:(pos2+1)*Z, pos1*Y:(pos1+1)*Y] = np.swapaxes(data[i,:,::-1],0,1)
        elif mosaic_axis == 1:
            tmp = np.zeros((subN*Z, subN*X))
            for i in range(N):
                pos1, pos2 = divmod(i, subN)
                tmp[pos2*Z:(pos2+1)*Z, pos1*X:(pos1+1)*X] = np.swapaxes(data[:,i,::-1],0,1)
        elif mosaic_axis == 2:
            tmp = np.zeros((subN*Y, subN*X))
            for i in range(N):
                pos1, pos2 = divmod(i, subN)
                tmp[pos2*Y:(pos2+1)*Y, pos1*X:(pos1+1)*X] = np.swapaxes(data[:,::-1,i],0,1)

        pl.imshow(tmp, interpolation='nearest', cmap = pl.cm.viridis)
        pl.axis('off')
        # pl.subplots_adjust(wspace=0, hspace=0)


    # Orthoview
    if plot_orthoview:
        cx, cy, cz = X//2, Y//2, Z//2

        print('Data center is {} {} {}'.format(cx, cy, cz))

        dataX = np.swapaxes(data[cx,:,::-1],0,1)
        dataY = np.swapaxes(data[:,cy,::-1],0,1)
        dataZ = np.swapaxes(data[:,::-1,cz],0,1)

        datamin = min(dataX.min(), dataY.min(), dataZ.min())
        datamax = min(dataX.max(), dataY.max(), dataZ.max())


        pl.figure()
        pl.subplot(1,3,1)
        pl.imshow(dataX, interpolation='nearest', cmap = pl.cm.viridis, vmin = datamin, vmax = datamax)
        pl.axis('off')

        pl.subplot(1,3,2)
        pl.imshow(dataY, interpolation='nearest', cmap = pl.cm.viridis, vmin = datamin, vmax = datamax)
        pl.axis('off')

        pl.subplot(1,3,3)
        pl.imshow(dataZ, interpolation='nearest', cmap = pl.cm.viridis, vmin = datamin, vmax = datamax)
        pl.axis('off')


    # Histogram
    if plot_histogram:
        nbins = 100
        # enforcing mask
        data_hist = data[mask]

        if args.hist_min is None:
            hist_min = data_hist.min()
        else:
            hist_min = args.hist_min

        if args.hist_max is None:
            hist_max = data_hist.max()
        else:
            hist_max = args.hist_max

        data_hist = data_hist[data_hist >= hist_min]
        data_hist = data_hist[data_hist <= hist_max]

        print('Histogram of masked volume with {} bins from {:.2e} to {:.2e}'.format(nbins, hist_min, hist_max))
        print('mean = {:.3e}   std = {:.3e}'.format(data_hist.mean(), data_hist.std()))
        pl.figure()
        pl.hist(data_hist, bins = nbins)
        if plot_histogram_log == True:
            pl.yscale('log')
        pl.grid('minor')


    pl.show()


if __name__ == '__main__':
    main()


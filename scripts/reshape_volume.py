#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import argparse
import numpy as np 
import nibabel as nib
import os

DESCRIPTION =   'Swap the dimensions of acquired post-mortem dMRI data to resemble MNI space. Cornelius Eichner 2020'

np.set_printoptions(precision=2)


def buildArgsParser():
    p = argparse.ArgumentParser(description=DESCRIPTION)

    p.add_argument('--in', dest='input', action='store', type=str,
                            help='Path of the input file (Nifti)')

    p.add_argument('--out', dest='out', action='store', type=str,
                            help='Path of the output file')

    p.add_argument('--res', dest='res', action='store', type=float,
                            help='Resolution of the input file, required for affine matrix')

    p.add_argument('--ord', dest='ord', action='store', type=str, default = '2,0,1', 
                            help='Optional: Transpose following axes (only first 3 dimensions, e.g., "--ord 2,0,1" rearranges (0,1,2) -> (2,0,1) )')

    p.add_argument('--inv', dest='inv', action='store', type=str, default = 'none', 
                            help='Optional: Invert given dimensions after transpose')

    p.add_argument('--ori', dest='ori', action='store', type=str, default='rad',
                            help='Optional: Orientation of the output file, "rad": radiological, "neu": neurological')

    return p


def main():
    # Load parser to read data from command line input
    parser 	= buildArgsParser()
    args 	= parser.parse_args()

    print('\nSwapping Data Dimensions to Resemble MNI Convention\n')

    # Load input variables
    DATA_IN 	= os.path.realpath(args.input)
    DATA_OUT 	= os.path.realpath(args.out)
    RES 		= args.res
    ORIENTATION = args.ori
    ORD 		= tuple(map(int, (args.ord).split(','))) 
    if args.inv == 'none':
        INV     = None
    else:
        INV		= tuple(map(int, (args.inv).split(','))) 

    
    # Read Data
    print('Loading Input Data {}'.format(DATA_IN))
    data = nib.load(DATA_IN).get_fdata().astype(np.float)
    aff = nib.load(DATA_IN).affine
    print('Original Data Shape {} \n'.format(data.shape))
    
    # Swap data along given dimensions 
    print('Swapping Input Data Dimensions')

    if len(data.shape) == 3:
        # data_swap = np.flip(np.transpose(data, axes = (2,0,1)), axis = (0,1,2))
        data_swap = np.transpose(data, axes = ORD)
    elif len(data.shape) == 4:
        print('Swap Only First 3 Dimensions')
        data_swap = np.transpose(data, axes = ORD + (3,))
    else:
    	print('Data Shape {} invalid for operation'.format(data.shape))


    if INV:
       data_swap = np.flip(data_swap, axis = INV) 


    print('Swapped Data Shape: {}\n'.format(data_swap.shape))

    aff_cust = RES*np.eye(4)

    if ORIENTATION == 'rad':
    	print('Saving Data in Radiological Convention')

    	aff_cust[0,0] *= -1 # Flipping the x axis
    	aff_cust[0, 3] = -(data_swap.shape[0]-1)*RES # Adjust for data zero point being flipped


    elif ORIENTATION == 'neu':
    	print('Saving Data in Neurological Convention')

    	data_swap = np.flip(data_swap, axis = 0)


    print('Custom Affine Tranformation Matrix\n{}\n'.format(aff_cust))

    # Save Swapped Data
    print('Saving Swapped Data under {}'.format(DATA_OUT))
    nib.save(nib.Nifti1Image(data_swap.astype(np.float32), aff_cust), DATA_OUT)

if __name__ == '__main__':
    main()

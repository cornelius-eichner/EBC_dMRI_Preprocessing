#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import argparse
import numpy as np 
import os
# from __future__ import print_function

DESCRIPTION =   'Reordering bvecs file i.e., swapping and inverting dimensions. Cornelius Eichner 2018'

np.set_printoptions(precision=2)

def buildArgsParser():
    p = argparse.ArgumentParser(description=DESCRIPTION)
    p.add_argument('--in', dest='input', action='store', type=str,
                            help='Path of the input bvec file')

    p.add_argument('--ord', dest='ord', action='store', type=str, default='0,1,2',
                            help='Optional: Ordering of new bvecs file as csv (e.g., 0,2,1)')

    p.add_argument('--inv', dest='inv', action='store', type=str, default='0,0,0',
                            help='Optional: Mask to chose dimensions of original bvecs file for inversion (e.g., 0,1,0)')

    p.add_argument('--out', dest='out', action='store', type=str,
                            help='Path of the output')

    return p


def main():
    # Load parser to read data from command line input
    parser = buildArgsParser()
    args = parser.parse_args()

    # Load input variables
    BVEC_IN = os.path.realpath(args.input)
    ORDER = args.ord
    INV = args.inv
    BVEC_OUT = os.path.realpath(args.out)
   
    # Read input bvecs file
    bvec = np.genfromtxt(BVEC_IN)

    if bvec.shape[0] > bvec.shape[1]:
        bvec = bvec.T


    print('Original bvecs: \n', bvec)
   
    # Create and appy inversion mask
    inv =  np.fromstring(INV, dtype=int, count=-1, sep=',')
    mask = (-1 * (inv-0.5) / np.abs(inv-0.5)).astype(int)
    # mask = mask.astype(int)
    bvec_inv = mask[:,None]*bvec

    new_order = np.fromstring(ORDER, dtype=int, count=-1, sep=',')
    
    # Reorder the bvecs array to match the desired order
    new_bvec = np.array((bvec_inv[new_order[0],None].flatten(),bvec_inv[new_order[1],None].flatten(),bvec_inv[new_order[2],None].flatten()))
    print('\nReordered bvecs: \n', new_bvec)

    # Save new file
    np.savetxt(BVEC_OUT, new_bvec, fmt='%6.5f', delimiter=' ')

if __name__ == '__main__':
    main()

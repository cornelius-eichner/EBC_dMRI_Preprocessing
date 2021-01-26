#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import argparse
import numpy as np
import os


DESCRIPTION =   """
Round bval files to the nearest thousand. Required for b-shell extraction. 
Cornelius Eichner 2020
"""

np.set_printoptions(precision=2)

def buildArgsParser():
    p = argparse.ArgumentParser(description=DESCRIPTION)
    p.add_argument('--in', dest='input', action='store', type=str,
                            help='Name of the input bval file')

    p.add_argument('--out', dest='output', action='store', type=str,
                            help='Name of the output bval file')

    return p


def main():
    # Load parser to read data from command line input
    parser = buildArgsParser()
    args = parser.parse_args()

    # Load input variables
    PATH_IN = os.path.realpath(args.input)
    PATH_OUT = os.path.realpath(args.output)

    # Read input bvecs file
    bval = np.genfromtxt(PATH_IN)

    # Save rounded bvals
    np.savetxt(PATH_OUT, np.round(bval,-3), fmt='%d', delimiter=' ')



if __name__ == '__main__':
    main()
